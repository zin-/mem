import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/schedule.dart';

class ScheduleClient extends Repository<Schedule>
    with Receiver<Schedule, void> {
  @override
  Future<void> receive(Schedule entity) => v(
        () async {
          if (entity is PeriodicSchedule) {
            await AndroidAlarmManager.periodic(
              entity.duration,
              entity.id,
              entity.callback,
              startAt: entity.startAt,
              params: entity.params,
            );
          } else if (entity is TimedSchedule) {
            await AndroidAlarmManager.oneShotAt(
              entity.startAt,
              entity.id,
              entity.callback,
              params: entity.params,
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
        () async => await AndroidAlarmManager.cancel(id),
        {
          "id": id,
        },
      );

  ScheduleClient._();

  static ScheduleClient? _instance;

  factory ScheduleClient() => v(
        () {
          if (defaultTargetPlatform == TargetPlatform.android) {
            AndroidAlarmManager.initialize();
          }

          return _instance ??= ScheduleClient._();
        },
      );
}
