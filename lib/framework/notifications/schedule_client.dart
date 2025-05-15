import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/framework/workmanager_wrapper.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/schedule.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/permissions/permission_handler_wrapper.dart';

class ScheduleClient extends Repository<Schedule> {
  static ScheduleClient? _instance;
  late final WorkmanagerWrapper? _workmanagerWrapper = v(
    () => defaultTargetPlatform == TargetPlatform.android
        ? WorkmanagerWrapper()
        : null,
  );

  ScheduleClient._();

  factory ScheduleClient() => v(
        () => _instance ??= ScheduleClient._(),
        {
          '_instance': _instance,
        },
      );

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
          } else if (await PermissionHandlerWrapper().request(
            [Permission.notification],
          )) {
            if (entity is PeriodicSchedule) {
              await _workmanagerWrapper?.registerPeriodicTask(
                Task.notify,
                entity.startAt,
                entity.id,
                entity.params,
                entity.duration,
              );
            } else if (entity is TimedSchedule) {
              await _workmanagerWrapper?.registerOneOffTask(
                Task.notify,
                entity.startAt,
                entity.id,
                entity.params,
              );
            }
          }
        },
        {
          "entity": entity,
        },
      );

  Future<void> discard(int id) => v(
        () async {
          await _workmanagerWrapper?.cancel(id);
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
