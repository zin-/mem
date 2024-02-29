import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/schedule.dart';

class ScheduleClient extends Repository<Schedule>
    with Receiver<Schedule, void> {
  @override
  Future<void> receive(Schedule entity) => v(
        () async => await AndroidAlarmManager.periodic(
          entity.duration,
          entity.id,
          entity.callback,
          startAt: entity.startAt,
          params: entity.params,
        ),
        {
          "entity": entity,
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
