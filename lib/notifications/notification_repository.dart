import 'package:mem/framework/repository_v3.dart';
import 'package:mem/logger/log_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'flutter_local_notifications.dart';
import 'mem_notifications.dart';
import 'notification.dart';

const _androidDefaultIconPath = 'ic_launcher_foreground';

class NotificationActionEntity {
  final String id;
  final String title;

  NotificationActionEntity(this.id, this.title);
}

class NotificationRepository extends RepositoryV3<Notification, Future<void>> {
  final FlutterLocalNotificationsWrapper _flutterLocalNotificationsWrapper;

  Future<bool> initialize(
    OnNotificationActionTappedCallback notificationActionHandler,
    Function(int memId)? showMemDetailPage,
  ) =>
      v(
        () async {
// FIXME 現時点では、通知に対する操作をテストで実行できない
// coverage:ignore-start
          showMemDetailPageHandler(Map<dynamic, dynamic> payload) {
            if (showMemDetailPage != null && payload.containsKey(memIdKey)) {
              final memId = payload[memIdKey];
              if (memId is int) {
                showMemDetailPage(memId);
              }
            }
          }
// coverage:ignore-end

          tz.initializeTimeZones();

          final initialized =
              await _flutterLocalNotificationsWrapper.initialize(
            _androidDefaultIconPath,
// FIXME 現時点では、通知に対する操作をテストで実行できない
// coverage:ignore-start
            (notificationId, payload) => showMemDetailPageHandler(payload),
// coverage:ignore-end
            notificationActionHandler,
          );

          if (initialized) {
            await _flutterLocalNotificationsWrapper
                .receiveOnLaunchAppNotification(
// FIXME 現時点では、通知に対する操作をテストで実行できない
// coverage:ignore-start
              (notificationId, payload) => showMemDetailPageHandler(payload),
// coverage:ignore-end
            );
          }

          return initialized;
        },
      );

  @override
  Future<void> receive(
    Notification payload,
  ) =>
      v(
        () async {
          if (payload is RepeatedNotification) {
            await _flutterLocalNotificationsWrapper.zonedSchedule(
              payload.id,
              payload.title,
              payload.body,
              tz.TZDateTime.from(payload.notifyAt, tz.local),
              payload.payloadJson,
              payload.actions,
              payload.channel.id,
              payload.channel.name,
              payload.channel.description,
              payload.interval,
            );
          } else if (payload is OneTimeNotification) {
            await _flutterLocalNotificationsWrapper.zonedSchedule(
              payload.id,
              payload.title,
              payload.body,
              tz.TZDateTime.from(payload.notifyAt, tz.local),
              payload.payloadJson,
              payload.actions,
              payload.channel.id,
              payload.channel.name,
              payload.channel.description,
            );
          } else if (payload is CancelNotification) {
            await discard(payload.id);
          }
        },
        payload,
      );

  Future<void> discard(int id) => v(
        () async => _flutterLocalNotificationsWrapper.cancel(id),
        {'id': id},
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
