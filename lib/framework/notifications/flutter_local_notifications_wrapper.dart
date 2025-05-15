import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/main.dart';

import 'mem_notifications.dart';
import 'notification/channel.dart';

// TODO Windows, Web, Linuxでの通知を実装する
//  https://github.com/zin-/mem/issues/303
class FlutterLocalNotificationsWrapper {
  bool _pluginIsInitializing = false;

  final String androidDefaultIconPath;

  Future<fln.FlutterLocalNotificationsPlugin>
      get _flutterLocalNotificationsPlugin => v(
            () async {
              final flutterLocalNotificationsPlugin =
                  fln.FlutterLocalNotificationsPlugin();
              if (!_pluginIsInitializing) {
                _pluginIsInitializing = true;
                await flutterLocalNotificationsPlugin.initialize(
                  fln.InitializationSettings(
                    android: fln.AndroidInitializationSettings(
                        androidDefaultIconPath),
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

  Future<void> show(
    int id,
    String title,
    String? body,
    NotificationChannel channel,
    Map<String, dynamic> payload,
  ) =>
      v(
        () async {
          return await (await _flutterLocalNotificationsPlugin).show(
            id,
            title,
            body,
            channel.convert(),
            payload: jsonEncode(payload),
          );
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
                  fln.AndroidFlutterLocalNotificationsPlugin>();

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
  fln.NotificationResponse details,
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
          case fln.NotificationResponseType.selectedNotification:
            if (payload.containsKey(memIdKey)) {
              await onSelected(payload[memIdKey]);
            }
            break;

          case fln.NotificationResponseType.selectedNotificationAction:
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

extension on NotificationChannel {
  fln.NotificationDetails convert() => fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          id,
          name,
          channelDescription: description,
          importance: importance.convert(),
          groupKey: groupKey,
          actions: actionList
              .map((e) => fln.AndroidNotificationAction(e.id, e.title))
              .toList(growable: false),
          usesChronometer: usesChronometer,
          ongoing: ongoing,
          autoCancel: autoCancel,
          playSound: playSound,
        ),
      );
}

extension on Importance {
  fln.Importance convert() => switch (this) {
        Importance.mid => fln.Importance.defaultImportance,
        Importance.high => fln.Importance.high,
      };
}
