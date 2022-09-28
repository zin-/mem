import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _androidDefaultIconPath = 'ic_launcher_foreground';
const _notificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'channelId',
    'channelName',
  ),
);

class NotificationEntity {}

class NotificationRepository {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> receive(int id, String title, DateTime notifyAt) => v(
        {'id': id, 'title': title, 'notifyAt': notifyAt},
        () {
          return _flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            title,
            null,
            tz.TZDateTime.from(notifyAt, tz.local),
            _notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true,
          );
        },
      );

  static NotificationRepository? _instance;

  NotificationRepository._() {
    _initialize();
  }

  factory NotificationRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory NotificationRepository.initialize() {
    var tmp = NotificationRepository._();

    _instance = tmp;

    return tmp;
  }

  _initialize() => v(
        {},
        () async {
          tz.initializeTimeZones();
          _flutterLocalNotificationsPlugin.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings(
                _androidDefaultIconPath,
              ),
            ),
          );
        },
      );

  factory NotificationRepository.withMock(NotificationRepository mock) {
    _instance = mock;
    return mock;
  }
}
