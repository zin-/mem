import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger.dart';
import 'package:mem/services/mem_service.dart';
import 'package:mem/wrappers/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _androidDefaultIconPath = 'ic_launcher_foreground';

const _doneActionId = 'done';

doneAction(int memId) async {
  // FIXME 一つの関数を呼び出すだけで完結したい
  MemService().save(
    MemDetail(
      (await MemService().fetchMemById(memId))..doneAt = DateTime.now(),
      await MemService().fetchMemItemsByMemId(memId),
    ),
  );
}

const _reminderNotification = NotificationDetails(
  android: AndroidNotificationDetails(
    'reminder',
    'Reminder',
    channelDescription: 'To remind at specific time.',
    actions: [
      AndroidNotificationAction(_doneActionId, 'Done'),
    ],
  ),
);

Future<void> notificationActionHandler(
  int notificationId,
  String actionId,
  String? input,
  Map<dynamic, dynamic> payload,
) =>
    v(
      {
        'id': notificationId,
        'actionId': actionId,
        'input': input,
        'payload': payload
      },
      () async {
        if (actionId == _doneActionId) {
          if (payload.containsKey(memIdKey)) {
            final memId = payload[memIdKey];
            if (memId is int) {
              await doneAction(memId);
            }
          }
        }
      },
    );

const memIdKey = 'memId';

class NotificationRepository {
  final FlutterLocalNotificationsWrapper _flutterLocalNotificationsWrapper;

  // var initialized = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> initialize([Function(int memId)? showMemDetailPage]) => v(
        {},
        () async {
          showMemDetailPageHandler(Map<dynamic, dynamic> payload) {
            if (showMemDetailPage != null && payload.containsKey(memIdKey)) {
              final memId = payload[memIdKey];
              if (memId is int) {
                showMemDetailPage(memId);
              }
            }
          }

          tz.initializeTimeZones();

          final initialized =
              await _flutterLocalNotificationsWrapper.initialize(
            _androidDefaultIconPath,
            (notificationId, payload) => showMemDetailPageHandler(payload),
            notificationActionHandler,
          );

          if (initialized) {
            await _flutterLocalNotificationsWrapper
                .receiveOnLaunchAppNotification(
              (notificationId, payload) => showMemDetailPageHandler(payload),
            );
          }

          return initialized;
        },
      );

  Future<void> receive(int id, String title, DateTime notifyAt) => v(
        {'id': id, 'title': title, 'notifyAt': notifyAt},
        () {
          return _flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            null,
            tz.TZDateTime.from(notifyAt, tz.local),
            _reminderNotification,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true,
            payload: json.encode({memIdKey: id}),
          );
        },
      );

  Future<void> discard(int id) => v(
        {'id': id},
        () async => _flutterLocalNotificationsPlugin.cancel(id),
      );

  NotificationRepository._(this._flutterLocalNotificationsWrapper);

  static NotificationRepository? _instance;

  factory NotificationRepository({
    FlutterLocalNotificationsWrapper? flutterLocalNotificationsWrapper,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = NotificationRepository._(
        flutterLocalNotificationsWrapper ?? FlutterLocalNotificationsWrapper(),
      );
      _instance = tmp;
    }
    return tmp;
  }
}
