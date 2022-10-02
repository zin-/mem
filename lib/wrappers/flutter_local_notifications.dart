import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/notification_repository.dart';

typedef OnNotificationTappedCallback = Function(
  int notificationId,
  Map<dynamic, dynamic> payload,
);
typedef OnNotificationActionTappedCallback = Function(
  int notificationId,
  String actionId,
  String? input,
  Map<dynamic, dynamic> payload,
);

class FlutterLocalNotificationsWrapper {
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
        () async =>
            (await _flutterLocalNotificationsPlugin.initialize(
              InitializationSettings(
                android: AndroidInitializationSettings(androidDefaultIconPath),
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
            true,
      );

  Future<void> receiveOnLaunchAppNotification(
    OnNotificationTappedCallback onNotificationTapped,
  ) =>
      v(
        {
          'onNotificationTapped': onNotificationTapped,
        },
        () async {
          final notificationAppLaunchDetails =
              await _flutterLocalNotificationsPlugin
                  .getNotificationAppLaunchDetails();

          if (notificationAppLaunchDetails?.didNotificationLaunchApp == false) {
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
        },
      );

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
void onNotificationTappedBackground(NotificationResponse response) => t(
      {'response': response},
      () async {
        await openDatabase();

        await _notificationResponseHandler(
          response,
          (notificationId, payload) => null,
          (notificationId, actionId, input, payload) =>
              notificationActionHandler(
            notificationId,
            actionId,
            input,
            payload,
          ),
        );
      },
    );

_notificationResponseHandler(
  NotificationResponse notificationResponse,
  OnNotificationTappedCallback onNotificationTapped,
  OnNotificationActionTappedCallback? onNotificationActionTappedCallback,
) {
  final notificationId = notificationResponse.id;
  if (notificationId == null) {
    return;
  }

  final notificationPayload = notificationResponse.payload;
  final payload =
      notificationPayload == null ? {} : json.decode(notificationPayload);

  switch (notificationResponse.notificationResponseType) {
    case NotificationResponseType.selectedNotification:
      onNotificationTapped(
        notificationId,
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

      onNotificationActionTappedCallback.call(
        notificationId,
        actionId,
        notificationResponse.input,
        payload,
      );
      break;
  }
}
