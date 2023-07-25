// coverage:ignore-file
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/notifications/channels.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:timezone/timezone.dart';

import 'notification/action.dart';
import 'notification/channel.dart';
import 'notification/repeated_notification.dart';

typedef OnNotificationTappedCallback = Function(
  int id,
  Map<dynamic, dynamic> payload,
);
typedef OnNotificationActionTappedCallback = Function(
  int id,
  String actionId,
  String? input,
  Map<dynamic, dynamic> payload,
);

class NotificationsWrapper {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> initialize(
    String androidDefaultIconPath,
    OnNotificationTappedCallback onNotificationTappedCallback,
    OnNotificationActionTappedCallback? onNotificationActionTappedCallback,
  ) =>
      v(
        () async {
          return (await _flutterLocalNotificationsPlugin.initialize(
                InitializationSettings(
                  android:
                      AndroidInitializationSettings(androidDefaultIconPath),
                ),
                onDidReceiveNotificationResponse: (details) =>
                    _notificationResponseHandler(
                  details,
                  onNotificationTappedCallback,
                  onNotificationActionTappedCallback,
                ),
                onDidReceiveBackgroundNotificationResponse:
                    onNotificationTappedBackground,
              )) ==
              true;
        },
        {
          'androidDefaultIconPath': androidDefaultIconPath,
          'onNotificationTappedCallback': onNotificationTappedCallback,
          'onNotificationActionTappedCallback':
              onNotificationActionTappedCallback,
        },
      );

  Future<void> receiveOnLaunchAppNotification(
    OnNotificationTappedCallback onNotificationTapped,
  ) =>
      v(
        () async {
          if (Platform.isAndroid) {
            final notificationAppLaunchDetails =
                await _flutterLocalNotificationsPlugin
                    .getNotificationAppLaunchDetails();

            if (notificationAppLaunchDetails?.didNotificationLaunchApp ==
                false) {
              return;
            }

            final notificationResponse =
                notificationAppLaunchDetails?.notificationResponse;

            if (notificationResponse == null) {
              return;
            }

            _notificationResponseHandler(
              notificationResponse,
              onNotificationTapped,
              null,
            );
          }
        },
        {
          'onNotificationTapped': onNotificationTapped,
        },
      );

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

  NotificationsWrapper._();

  static NotificationsWrapper? _instance;

  factory NotificationsWrapper() =>
      _instance ??= _instance = NotificationsWrapper._();

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

@pragma('vm:entry-point')
void onNotificationTappedBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();

  info({'response': response});

  await openDatabase();

  // ここで呼び出すと、デバイスのcontextがないのでen固定になるかもしれない
  prepareNotifications();

  await _notificationResponseHandler(
    response,
    (id, payload) => null,
    (id, actionId, input, payload) => notificationActionHandler(
      id,
      actionId,
      input,
      payload,
    ),
  );
}

_notificationResponseHandler(
  NotificationResponse notificationResponse,
  OnNotificationTappedCallback onNotificationTapped,
  OnNotificationActionTappedCallback? onNotificationActionTappedCallback,
) {
  final id = notificationResponse.id;
  if (id == null) {
    return;
  }

  final notificationPayload = notificationResponse.payload;
  final payload =
      notificationPayload == null ? {} : json.decode(notificationPayload);

  switch (notificationResponse.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      onNotificationTapped(
        id,
        payload,
      );
      break;

    case NotificationResponseType.selectedNotificationAction:
      if (onNotificationActionTappedCallback == null) {
        return;
      }
      final actionId = notificationResponse.actionId;
      if (actionId == null) {
        return;
      }

      onNotificationActionTappedCallback(
        id,
        actionId,
        notificationResponse.input,
        payload,
      );
      break;
  }
}