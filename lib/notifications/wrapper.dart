import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:timezone/timezone.dart';

import 'client.dart';
import 'mem_notifications.dart';
import 'notification/action.dart';
import 'notification/channel.dart';
import 'notification/repeated_notification.dart';

class NotificationsWrapper {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late final Future<bool?> _pluginIsInitialized;

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
        () => _flutterLocalNotificationsPlugin.zonedSchedule(
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
          matchDateTimeComponents:
              // TODO NotificationInterval.perDay以外も指定できるようにする
              interval == null ? null : DateTimeComponents.time,
        ),
        {
          'id': id,
          'title': title,
          'body': body,
          'tzDateTime': tzDateTime,
          'payload': payload,
          'channel': channel,
        },
      );

  Future<void> cancel(int notificationId) => v(
        () => _flutterLocalNotificationsPlugin.cancel(notificationId),
        {'notificationId': notificationId},
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

  Future<bool> handleAppLaunchDetails() => v(
        () async => _pluginIsInitialized.then((value) async {
          final appLaunchDetails = await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

          if (appLaunchDetails?.didNotificationLaunchApp == false) {
            return false;
          }
// アプリが停止状態で、通知から起動される必要があるため現状テストする方法がない
// coverage:ignore-start
          final details = appLaunchDetails?.notificationResponse;

          if (details == null) {
            return false;
          }

          onDidReceiveNotificationResponse(details);

          return true;
// coverage:ignore-end
        }),
      );

  NotificationsWrapper._(
    String androidDefaultIconPath,
  ) {
    v(
      () {
        _pluginIsInitialized = _flutterLocalNotificationsPlugin.initialize(
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
      _instance ??= NotificationsWrapper._(androidDefaultIconPath);
}

// extension on NotificationInterval {
//   DateTimeComponents convert() {
//     switch (this) {
//       case NotificationInterval.perDay:
//         return DateTimeComponents.time;
//       case NotificationInterval.perWeek:
//         return DateTimeComponents.dayOfWeekAndTime;
//       case NotificationInterval.perMonth:
//         return DateTimeComponents.dayOfMonthAndTime;
//       case NotificationInterval.perYear:
//         return DateTimeComponents.dateAndTime;
//     }
//   }
// }

// 分かりやすさのために、entry-pointはすべてmain.dartに定義したいが、
// NotificationResponseがライブラリの型なので、ここで定義する
// ライブラリから呼び出されるentry-pointなのでprivateにすることもできない
@pragma('vm:entry-point')
Future<void> onDidReceiveNotificationResponse(NotificationResponse details) =>
    i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await openDatabase();
        NotificationClientV2();

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

            if (payload.containsKey(memIdKey)) {
              final memId = payload[memIdKey];
              await NotificationClientV2()
                  .notificationActions
                  .singleWhere((element) => element.id == actionId)
                  .onTapped(memId as int);
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
