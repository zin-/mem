import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mem/logger.dart';

const _androidDefaultIconPath = 'ic_launcher_foreground';
// const _androidDefaultIconPath = '@drawable/ic_launcher_foreground.png';
// const _notificationDetails = NotificationDetails(
//   android: AndroidNotificationDetails(
//     'channelId',
//     'channelName',
//   ),
// );

class NotificationRepository {
  receive() => v(
        {},
        () {},
      );

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static NotificationRepository? _instance;

  NotificationRepository._();

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

    t(
      {},
      () => tmp._flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(
            _androidDefaultIconPath,
          ),
        ),
      ),
    );

    return tmp;
  }

  factory NotificationRepository.withMock(NotificationRepository mock) {
    _instance = mock;
    return mock;
  }
}
