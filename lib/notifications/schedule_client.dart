import 'package:collection/collection.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/notifications/android_alarm_manager_wrapper.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/repositories/mem_notification_repository.dart';

class ScheduleClient extends Repository<Schedule>
    with Receiver<Schedule, void> {
  static ScheduleClient? _instance;
  final AndroidAlarmManagerWrapper _androidAlarmManagerWrapper;
  final Future<void> Function(int id, Map<String, dynamic> params)
      _scheduleCallback;

  ScheduleClient._(
    this._androidAlarmManagerWrapper,
    this._scheduleCallback,
  );

  factory ScheduleClient() => v(
        () => _instance ??= ScheduleClient._(
          AndroidAlarmManagerWrapper(),
          scheduleCallback,
        ),
        {
          '_instance': _instance,
        },
      );

  static void resetSingleton() => v(
        () {
          AndroidAlarmManagerWrapper.resetSingleton();
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );

  @override
  Future<void> receive(Schedule entity) => v(
        () async {
          if (entity is PeriodicSchedule) {
            await _androidAlarmManagerWrapper.periodic(
              entity.duration,
              entity.id,
              _scheduleCallback,
              entity.startAt,
              entity.params,
            );
          } else if (entity is TimedSchedule) {
            await _androidAlarmManagerWrapper.oneShotAt(
              entity.startAt,
              entity.id,
              _scheduleCallback,
              entity.params,
            );
          } else if (entity is CancelSchedule) {
            await discard(entity.id);
          }
        },
        {
          "entity": entity,
        },
      );

  Future<void> discard(int id) => v(
        () async => await _androidAlarmManagerWrapper.cancel(id),
        {"id": id},
      );
}

Future<void> scheduleCallback(int id, Map<String, dynamic> params) => i(
      () async {
        await openDatabase();

        final memId = params[memIdKey] as int;

        final notificationType = NotificationType.values.singleWhere(
          (element) => element.name == params[notificationTypeKey],
        );

        switch (notificationType) {
          case NotificationType.repeat:
            if (await _shouldNotify(memId)) {
              await NotificationClient().show(
                notificationType,
                memId,
              );
            }
            break;

          default:
            await NotificationClient().show(
              notificationType,
              memId,
            );
            break;
        }
      },
      {"id": id, "params": params},
    );

Future<bool> _shouldNotify(int memId) => v(
      () async {
        final savedMemNotifications =
            await MemNotificationRepository().shipByMemId(memId);
        final repeatByDayOfWeekMemNotifications = savedMemNotifications.where(
          (element) => element.isEnabled() && element.isRepeatByDayOfWeek(),
        );

        if (repeatByDayOfWeekMemNotifications.isNotEmpty) {
          final now = DateTime.now();
          if (!repeatByDayOfWeekMemNotifications
              .map((e) => e.time)
              .contains(now.weekday)) {
            return false;
          }
        }

        final repeatByNDayMemNotification =
            savedMemNotifications.singleWhereOrNull(
          (element) => element.isEnabled() && element.isRepeatByNDay(),
        );
        final lastActTime = await ActRepository()
            .findOneBy(memId: memId, latest: true)
            .then((value) =>
                value?.period.end ??
                // FIXME 永続化されている時点でstartは必ずあるので型で表現する
                value?.period.start!);

        if (lastActTime != null) {
          if (Duration(
                  days:
                      // FIXME 永続化されている時点でtimeは必ずあるので型で表現する
                      //  repeatByNDayMemNotification自体がないのは別の話
                      repeatByNDayMemNotification?.time! ?? 1) >
              DateTime.now().difference(lastActTime)) {
            return false;
          }
        }

        return true;
      },
    );
