// coverage:ignore-file
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/actions.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:timezone/timezone.dart';

import 'channels.dart';
import 'notification/action.dart';
import 'notification/channel.dart';
import 'notification/repeated_notification.dart';

class NotificationsWrapper {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> show(
    int id,
    String title,
    String? body,
    List<NotificationAction> actions,
    NotificationChannel channel,
    String? payload,
  ) =>
      v(
        () => _flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          _buildNotificationDetails(
            channel,
            actions,
          ),
          payload: payload,
        ),
        {
          id,
          title,
          body.toString(),
          actions,
          channel,
          payload,
        },
      );

  Future<void> zonedSchedule(
    int id,
    String title,
    String? body,
    TZDateTime tzDateTime,
    String? payload,
    List<NotificationAction> actions,
    NotificationChannel channel, [
    NotificationInterval? interval,
  ]) =>
      v(
        () async {
          if (Platform.isAndroid) {
            return _flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              title,
              body,
              tzDateTime,
              _buildNotificationDetails(
                channel,
                actions,
              ),
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.exact,
              payload: payload,
              matchDateTimeComponents: interval?.convert(),
            );
          }
        },
        {
          'id': id,
          'title': title,
          'body': body,
          'tzDateTime': tzDateTime,
          'payload': payload,
          'channel': channel,
        },
      );

  cancel(int id) => v(
        () {
          if (Platform.isAndroid) {
            _flutterLocalNotificationsPlugin.cancel(id);
          }
        },
        {
          'id': id,
        },
      );

  NotificationDetails _buildNotificationDetails(
    NotificationChannel channel,
    List<NotificationAction> actions,
  ) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          actions: actions
              .map((e) => AndroidNotificationAction(e.id, e.title))
              .toList(),
          usesChronometer: channel.usesChronometer,
          ongoing: channel.ongoing,
          autoCancel: channel.autoCancel,
        ),
      );

  NotificationsWrapper._(
    String androidDefaultIconPath,
  ) {
    i(
      () {
        _flutterLocalNotificationsPlugin.initialize(
          InitializationSettings(
            android: AndroidInitializationSettings(androidDefaultIconPath),
          ),
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
          onDidReceiveBackgroundNotificationResponse:
              onDidReceiveNotificationResponse,
        );
      },
      androidDefaultIconPath,
    );
  }

  static NotificationsWrapper? _instance;

  factory NotificationsWrapper(String androidDefaultIconPath) =>
      _instance ??= _instance = NotificationsWrapper._(androidDefaultIconPath);

  static resetWith(NotificationsWrapper? instance) => _instance = instance;
}

extension on NotificationInterval {
  DateTimeComponents convert() {
    switch (this) {
      case NotificationInterval.perDay:
        return DateTimeComponents.time;
      case NotificationInterval.perWeek:
        return DateTimeComponents.dayOfWeekAndTime;
      case NotificationInterval.perMonth:
        return DateTimeComponents.dayOfMonthAndTime;
      case NotificationInterval.perYear:
        return DateTimeComponents.dateAndTime;
    }
  }
}

// 分かりやすさのために、entry-pointはすべてmain.dartに定義したいが、
// NotificationResponseがライブラリの型なので、ここで定義する
// ライブラリから呼び出されるentry-pointなのでprivateにすることもできない
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse details) => i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await openDatabase();
        prepareNotifications();

        final id = details.id;
        if (id == null) {
          return;
        }

        final notificationPayload = details.payload;
        final payload =
            notificationPayload == null ? {} : json.decode(notificationPayload);

        switch (details.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            if (payload.containsKey(memIdKey)) {
              final memId = payload[memIdKey];
              if (memId is int) {
                await launchMemDetailPage(memId);
              }
            }
            break;

          case NotificationResponseType.selectedNotificationAction:
            final actionId = details.actionId;
            if (actionId == null) {
              return;
            }

            // TODO それぞれのactionの処理はaction側で定義したい
            if (actionId == doneMemActionId) {
              if (payload.containsKey(memIdKey)) {
                final memId = payload[memIdKey];
                if (memId is int) {
                  await MemService().doneByMemId(memId);
                }
              }
            } else if (actionId == startActActionId) {
              final memId = payload[memIdKey];
              if (memId is int) {
                await ActService().startBy(memId);
              }
            } else if (actionId == finishActiveActActionId) {
              final memId = payload[memIdKey];
              if (memId is int) {
                final act = (await ActRepository().shipActive())
                    .lastWhere((element) => element.memId == memId);
                await ActService().finish(act);
              }
            }
            break;
        }
      },
      {
        'notificationResponseType': details.notificationResponseType,
        'id': details.id,
        'actionId': details.actionId,
        'input': details.input,
        'payload': details.payload,
      },
    );
