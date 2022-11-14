// coverage:ignore-file
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/services/notification_service.dart';
import 'package:timezone/timezone.dart';

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

class FlutterLocalNotificationsWrapper {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> initialize(
    String androidDefaultIconPath,
    OnNotificationTappedCallback onNotificationTappedCallback,
    OnNotificationActionTappedCallback? onNotificationActionTappedCallback,
  ) =>
      v(
        {
          'androidDefaultIconPath': androidDefaultIconPath,
          'onNotificationTappedCallback': onNotificationTappedCallback,
          'onNotificationActionTappedCallback':
              onNotificationActionTappedCallback,
        },
        () async {
          if (Platform.isAndroid) {
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
          }

          return false;
        },
      );

  Future<void> receiveOnLaunchAppNotification(
    OnNotificationTappedCallback onNotificationTapped,
  ) =>
      v(
        {
          'onNotificationTapped': onNotificationTapped,
        },
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
      );

  Future<void> zonedSchedule(
    int id,
    String title,
    TZDateTime tzDateTime,
    String payload,
    List<NotificationActionEntity> actions,
    String channelId,
    String channelName,
    String channelDescription,
  ) =>
      v(
        {
          'id': id,
          'title': title,
          'tzDateTime': tzDateTime,
          'payload': payload,
          'channelId': channelId,
          'channelName': channelName,
          'channelDescription': channelDescription,
        },
        () async {
          if (Platform.isAndroid) {
            return _flutterLocalNotificationsPlugin.zonedSchedule(
              id,
              title,
              null,
              tzDateTime,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channelId,
                  channelName,
                  channelDescription: channelDescription,
                  actions: actions
                      .map((e) => AndroidNotificationAction(e.id, e.title))
                      .toList(),
                ),
              ),
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidAllowWhileIdle: true,
              payload: payload,
            );
          }
        },
      );

  cancel(int id) => v(
        {
          'id': id,
        },
        () {
          if (Platform.isAndroid) {
            _flutterLocalNotificationsPlugin.cancel(id);
          }
        },
      );

  FlutterLocalNotificationsWrapper._();

  static FlutterLocalNotificationsWrapper? _instance;

  factory FlutterLocalNotificationsWrapper() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = FlutterLocalNotificationsWrapper._();
      _instance = tmp;
    }
    return tmp;
  }
}

@pragma('vm:entry-point')
void onNotificationTappedBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeLogger();
  trace({'response': response});

  await openDatabase();

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
