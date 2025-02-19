import 'package:flutter/cupertino.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/framework/workmanager_wrapper.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/android_alarm_manager_wrapper.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/permissions/permission_handler_wrapper.dart';

class ScheduleClient extends Repository<Schedule> {
  static ScheduleClient? _instance;
  final AndroidAlarmManagerWrapper _androidAlarmManagerWrapper;
  final Future<void> Function(int id, Map<String, dynamic> params)
      _scheduleCallback;
  final WorkmanagerWrapper _workmanagerWrapper = WorkmanagerWrapper();

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
            if (await PermissionHandlerWrapper()
                .grant(Permission.notification)) {
              await _workmanagerWrapper.registerOneOffTask(
                Task.notify,
                entity.startAt,
                entity.id,
                entity.params,
              );
            }
          } else if (entity is CancelSchedule) {
            await discard(entity.id);
          }
        },
        {
          "entity": entity,
        },
      );

  Future<void> discard(int id) => v(
        () async {
          await _androidAlarmManagerWrapper.cancel(id);
          await _workmanagerWrapper.cancel(id);
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
