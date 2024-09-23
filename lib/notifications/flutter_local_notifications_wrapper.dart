import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';

import 'mem_notifications.dart';
import 'notification/channel.dart';

// TODO Windows, Web, Linuxでの通知を実装する
//  https://github.com/zin-/mem/issues/303
class FlutterLocalNotificationsWrapper {
  bool _pluginIsInitializing = false;

  final String androidDefaultIconPath;

  Future<FlutterLocalNotificationsPlugin>
      get _flutterLocalNotificationsPlugin => v(
            () async {
              final flutterLocalNotificationsPlugin =
                  FlutterLocalNotificationsPlugin();
              if (!_pluginIsInitializing) {
                _pluginIsInitializing = true;
                await flutterLocalNotificationsPlugin.initialize(
                  InitializationSettings(
                    android:
                        AndroidInitializationSettings(androidDefaultIconPath),
                  ),
                  onDidReceiveNotificationResponse:
                      onNotificationResponseReceived,
                  onDidReceiveBackgroundNotificationResponse:
                      onNotificationResponseReceived,
                );
              }
              return flutterLocalNotificationsPlugin;
            },
// coverage:ignore-start
            {
// coverage:ignore-end
              '_pluginIsInitializing': _pluginIsInitializing,
            },
          );

  FlutterLocalNotificationsWrapper._(
    this.androidDefaultIconPath,
  );

  static FlutterLocalNotificationsWrapper? _instance;

  factory FlutterLocalNotificationsWrapper(
    String androidDefaultIconPath,
  ) =>
      v(
        () => _instance ??= FlutterLocalNotificationsWrapper._(
          androidDefaultIconPath,
        ),
// coverage:ignore-start
        {
// coverage:ignore-end
          "_instance": _instance,
          "androidDefaultIconPath": androidDefaultIconPath
        },
      );

  static void resetSingleton() {
    _instance?._pluginIsInitializing = false;
    _instance = null;
  }

  Future<bool?> _requestPermission() =>
      v(() async => await (await _flutterLocalNotificationsPlugin)
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission());

  Future<void> show(
    int id,
    String title,
    String? body,
    NotificationChannel channel,
    Map<String, dynamic> payload,
  ) =>
      v(
        () async {
          if (await _requestPermission() == true) {
            return await (await _flutterLocalNotificationsPlugin).show(
              id,
              title,
              body,
              _buildNotificationDetails(
                channel,
              ),
              payload: jsonEncode(payload),
            );
          }
        },
// coverage:ignore-start
        {
// coverage:ignore-end
          "id": id,
          "title": title,
          "body": body,
          "channel": channel,
          "payload": payload,
        },
      );

  Future<void> cancel(int notificationId) => v(
        () async => await (await _flutterLocalNotificationsPlugin)
            .cancel(notificationId),
        {'notificationId': notificationId},
      );

  Future<void> cancelAll() => v(
        () async => await (await _flutterLocalNotificationsPlugin).cancelAll(),
      );

  Future<void> deleteNotificationChannels(
    Iterable<String> channelIds,
  ) =>
      v(
        () async {
          final p = (await _flutterLocalNotificationsPlugin)
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          for (var e in channelIds) {
            await p?.deleteNotificationChannel(e);
          }
        },
// coverage:ignore-start
        {
// coverage:ignore-end
          'channelIds': channelIds,
        },
      );

  NotificationDetails _buildNotificationDetails(
    NotificationChannel channel,
  ) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          actions: channel.actionList
              .map((e) => AndroidNotificationAction(e.id, e.title))
              .toList(growable: false),
          usesChronometer: channel.usesChronometer,
          ongoing: channel.ongoing,
          autoCancel: channel.autoCancel,
          playSound: channel.playSound,
        ),
      );

  Future<bool> handleAppLaunchDetails() => v(
        () async {
          final appLaunchDetails =
              await (await _flutterLocalNotificationsPlugin)
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

          onNotificationResponseReceived(details);

          return true;
// coverage:ignore-end
        },
      );
}

Future<void> onDidReceiveNotificationResponse(
  NotificationResponse details,
  Future<void> Function(dynamic memId) onSelected,
  Future<void> Function(
    String? actionId,
    dynamic memId,
  ) onActionSelected,
) =>
    v(
      () async {
        final notificationPayload = details.payload;
        final payload =
            notificationPayload == null ? {} : json.decode(notificationPayload);

        switch (details.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            if (payload.containsKey(memIdKey)) {
              await onSelected(payload[memIdKey]);
            }
            break;

          case NotificationResponseType.selectedNotificationAction:
            await onActionSelected(
              details.actionId,
              payload[memIdKey],
            );
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
