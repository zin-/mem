import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';

import 'client.dart';
import 'mem_notifications.dart';
import 'notification/channel.dart';

// TODO Windows, Web, Linuxでの通知を実装する
//  https://github.com/zin-/mem/issues/303
class FlutterLocalNotificationsWrapper {
  final String androidDefaultIconPath;
  bool _pluginIsInitialized = false;

  Future<FlutterLocalNotificationsPlugin>
      get _flutterLocalNotificationsPlugin => v(
            () async {
              final flutterLocalNotificationsPlugin =
                  FlutterLocalNotificationsPlugin();
              if (!_pluginIsInitialized) {
                await flutterLocalNotificationsPlugin.initialize(
                  InitializationSettings(
                    android:
                        AndroidInitializationSettings(androidDefaultIconPath),
                  ),
                  onDidReceiveNotificationResponse:
                      onDidReceiveNotificationResponse,
                  onDidReceiveBackgroundNotificationResponse:
                      onDidReceiveNotificationResponse,
                );
                _pluginIsInitialized = true;
              }
              return flutterLocalNotificationsPlugin;
            },
// coverage:ignore-start
            {
// coverage:ignore-end
              '_pluginIsInitialized': _pluginIsInitialized,
            },
          );

  Future<void> show(
    int id,
    String title,
    String? body,
    NotificationChannel channel,
    Map<String, dynamic> payload,
  ) =>
      v(
        () async => await (await _flutterLocalNotificationsPlugin).show(
          id,
          title,
          body,
          _buildNotificationDetails(
            channel,
          ),
          payload: jsonEncode(payload),
        ),
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

          onDidReceiveNotificationResponse(details);

          return true;
// coverage:ignore-end
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
    _instance?._pluginIsInitialized = false;
    _instance = null;
  }
}

// 分かりやすさのために、entry-pointはすべてmain.dartに定義したいが、
// NotificationResponseがライブラリの型なので、ここで定義する
// ライブラリから呼び出されるentry-pointなのでprivateにすることもできない
@pragma('vm:entry-point')
Future<void> onDidReceiveNotificationResponse(NotificationResponse details) =>
    i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await openDatabase();

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
              await NotificationClient()
                  .notificationChannels
                  .actionMap[actionId]
                  ?.onTapped(memId as int);
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
