import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mem/framework/notifications/alarm_scheduler.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/framework/workmanager_wrapper.dart';
import 'package:mem/features/logger/log_service.dart';
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
          ? AndroidAlarmScheduler()
          : null;

  static void resetSingleton() => v(
        () {
          WorkmanagerWrapper.resetSingleton();
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
                [Permission.notification],
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
Future<void> scheduleCallback(int id, Map<String, dynamic> params) => i(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        await NotificationClient().show(
          NotificationType.values.singleWhere(
            (element) => element.name == params[notificationTypeKey],
          ),
          params[memIdKey] as int?,
        );
      },
      {
        'id': id,
        'params': params,
      },
    );
