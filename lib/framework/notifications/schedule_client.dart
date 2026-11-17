import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mem/framework/notifications/android_alarm_manager_wrapper.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/schedule.dart';
import 'package:mem/framework/permissions/permission.dart';
import 'package:mem/framework/permissions/permission_handler_wrapper.dart';

class ScheduleClient extends Repository {
  static ScheduleClient? _instance;

  final AlarmScheduler? _scheduler;

  ScheduleClient._(this._scheduler);

  factory ScheduleClient({AlarmScheduler? scheduler}) => v(
        () => _instance ??= ScheduleClient._(
          scheduler ?? _defaultScheduler(),
        ),
        {
          '_instance': _instance,
          'scheduler': scheduler,
        },
      );

  static AlarmScheduler? _defaultScheduler() =>
      defaultTargetPlatform == TargetPlatform.android
          ? AndroidAlarmManagerWrapper()
          : null;

  static void resetSingleton() => v(
        () {
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );

  Future<void> receive(Schedule entity) => v(
        () async {
          if (entity is CancelSchedule) {
            await discard(entity.id);
          } else if (entity is TimedSchedule &&
              await PermissionHandlerWrapper().request(
                [
                  Permission.notification,
                  if (defaultTargetPlatform == TargetPlatform.android)
                    Permission.scheduleExactAlarm,
                ],
              )) {
            await _scheduler?.oneShotAt(
              id: entity.id,
              startAt: entity.startAt,
              params: entity.params,
              callback: scheduleCallback,
              exact: true,
              allowWhileIdle: true,
              wakeup: true,
              rescheduleOnReboot: true,
            );
          }
        },
        {
          "entity": entity,
        },
      );

  Future<void> discard(int id) => v(
        () async {
          await _scheduler?.cancel(id);
        },
        {"id": id},
      );
}

@pragma('vm:entry-point')
Future<void> scheduleCallback(
  int id,
  Map<String, dynamic> params, {
  DateTime? firedAt,
}) =>
    i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        final notificationType = NotificationType.values.singleWhere(
          (element) => element.name == params[notificationTypeKey],
        );
        final memId = params[memIdKey] as int?;

        await NotificationClient().show(
          notificationType,
          memId,
        );

        if (notificationType == NotificationType.repeat && memId != null) {
          final mem = await MemRepository()
              .shipById(memId)
              .then((entity) => entity.toDomain());
          // MemNotifyAt.repeat は now と同時刻なら同じ表示時刻を返す
          const justAfterFire = Duration(microseconds: 1);
          await NotificationClient().registerMemNotifications(
            mem,
            now: (firedAt ?? DateTime.now()).add(justAfterFire),
          );
        }
      },
      {
        'id': id,
        'params': params,
        'firedAt': firedAt,
      },
    );
