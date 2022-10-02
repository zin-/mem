import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger.dart';
import 'package:mem/main.dart';
import 'package:mem/services/mem_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _androidDefaultIconPath = 'ic_launcher_foreground';

const _doneActionId = 'done';

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

const memIdKey = 'memId';

class NotificationRepository {
  var initialized = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize([Function(int memId)? showMemDetailPage]) => v(
        {},
        () async {
          if (!initialized) {
            tz.initializeTimeZones();

            await _flutterLocalNotificationsPlugin.initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings(
                  _androidDefaultIconPath,
                ),
              ),
              onDidReceiveNotificationResponse: showMemDetailPage == null
                  ? null
                  : buildOnDidReceiveNotificationResponse(showMemDetailPage),
              onDidReceiveBackgroundNotificationResponse:
                  notificationTapBackground,
            );

            final notificationAppLaunchDetails =
                await _flutterLocalNotificationsPlugin
                    .getNotificationAppLaunchDetails();

            if (notificationAppLaunchDetails?.didNotificationLaunchApp ==
                true) {
              final notificationResponse =
                  notificationAppLaunchDetails?.notificationResponse;

              if (notificationResponse != null && showMemDetailPage != null) {
                notificationAction(
                  notificationResponse,
                  showMemDetailPage,
                );
              }
            }
          }
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

  NotificationRepository._();

  static NotificationRepository? _instance;

  factory NotificationRepository() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = NotificationRepository._();
      _instance = tmp;
    }
    return tmp;
  }
}

DidReceiveNotificationResponseCallback buildOnDidReceiveNotificationResponse(
  Function(int memId) showMemDetailPage,
) =>
    (NotificationResponse response) async => notificationAction(
          response,
          showMemDetailPage,
        );

void notificationAction(NotificationResponse response, Function action) => t(
      {
        'notificationResponseType': response.notificationResponseType,
        'id': response.id,
        'actionId': response.actionId,
        'input': response.input,
        'payload': response.payload
      },
      () {
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          final payload = response.payload;
          if (payload != null) {
            final Map payloadMap = json.decode(payload);
            final memId = payloadMap[memIdKey];
            if (memId != null) {
              action.call(memId);
            }
          }
        } else {
          final actionId = response.actionId;
          if (actionId == _doneActionId) {
            final payload = response.payload;
            if (payload != null) {
              final Map payloadMap = json.decode(payload);
              final memId = payloadMap[memIdKey];
              if (memId != null) {
                action.call(memId);
              }
            }
          }
        }
      },
    );

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  notificationAction(
    notificationResponse,
    (int memId) async {
      await openDatabase();

      MemService().save(
        MemDetail(
          (await MemService().fetchMemById(memId))..doneAt = DateTime.now(),
          await MemService().fetchMemItemsByMemId(memId),
        ),
      );
    },
  );
}
