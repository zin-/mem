import 'dart:convert';

import 'package:mem/logger.dart';
import 'package:mem/wrappers/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _androidDefaultIconPath = 'ic_launcher_foreground';

class NotificationActionEntity {
  final String id;
  final String title;

  NotificationActionEntity(this.id, this.title);
}

const memIdKey = 'memId';

class NotificationRepository {
  final FlutterLocalNotificationsWrapper _flutterLocalNotificationsWrapper;

  Future<bool> initialize(
    OnNotificationActionTappedCallback notificationActionHandler,
    Function(int memId)? showMemDetailPage,
  ) =>
      v(
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

  Future<void> receive(
    int id,
    String title,
    DateTime notifyAt,
    List<NotificationActionEntity> actions,
    String channelId,
    String channelName,
    String channelDescription,
  ) =>
      v(
        {
          'id': id,
          'title': title,
          'notifyAt': notifyAt,
          'actions': actions,
          'channelId': channelId,
          'channelName': channelName,
          'channelDescription': channelDescription,
        },
        () {
          return _flutterLocalNotificationsWrapper.zonedSchedule(
            id,
            title,
            tz.TZDateTime.from(notifyAt, tz.local),
            json.encode({memIdKey: id}),
            actions,
            channelId,
            channelName,
            channelDescription,
          );
        },
      );

  Future<void> discard(int id) => v(
        {'id': id},
        () async => _flutterLocalNotificationsWrapper.cancel(id),
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

  static void reset(NotificationRepository? notificationRepository) {
    _instance = notificationRepository;
  }
}
