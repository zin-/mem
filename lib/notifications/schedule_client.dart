import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/schedule.dart';

class ScheduleClient extends Repository<Schedule>
    with Receiver<Schedule, void> {
  static ScheduleClient? _instance;
  final _AndroidAlarmManagerWrapper _androidAlarmManagerWrapper;

  ScheduleClient._(this._androidAlarmManagerWrapper);

  factory ScheduleClient() => v(
        () {
          return _instance ??= ScheduleClient._(
            _AndroidAlarmManagerWrapper(),
          );
        },
      );

  @override
  Future<void> receive(Schedule entity) => v(
        () async {
          if (entity is PeriodicSchedule) {
            await _androidAlarmManagerWrapper.periodic(
              entity.duration,
              entity.id,
              entity.callback,
              entity.startAt,
              entity.params,
            );
          } else if (entity is TimedSchedule) {
            await _androidAlarmManagerWrapper.oneShotAt(
              entity.startAt,
              entity.id,
              entity.callback,
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

class _AndroidAlarmManagerWrapper {
  static _AndroidAlarmManagerWrapper? _instance;
  bool _initialized = false;

  _AndroidAlarmManagerWrapper._();

  factory _AndroidAlarmManagerWrapper() => v(
        () => _instance ??= _AndroidAlarmManagerWrapper._(),
        {"_instance": _instance},
      );

  Future<bool> oneShotAt(
    DateTime time,
    int id,
    Function callback,
    Map<String, dynamic> params,
  ) =>
      v(
        () async => await _initialize()
            ? await AndroidAlarmManager.oneShotAt(
                time,
                id,
                callback,
                params: params,
              )
            : false,
      );

  Future<bool> periodic(
    Duration duration,
    int id,
    Function callback,
    DateTime? startAt,
    Map<String, dynamic> params,
  ) =>
      v(
        () async => await _initialize()
            ? await AndroidAlarmManager.periodic(
                duration,
                id,
                callback,
                startAt: startAt,
                params: params,
              )
            : false,
        {
          "duration": duration,
          "id": id,
          "callback": callback,
          "startAt": startAt,
          "params": params,
        },
      );

  Future<bool> cancel(int id) => v(
        () async =>
            await _initialize() ? await AndroidAlarmManager.cancel(id) : false,
        {"id": id},
      );

  Future<bool> _initialize() => v(
        () async {
          if (_initialized) {
            return true;
          } else {
            if (defaultTargetPlatform == TargetPlatform.android) {
              return _initialized = await AndroidAlarmManager.initialize();
            } else {
              return false;
            }
          }
        },
        {
          "_initialized": _initialized,
          "defaultTargetPlatform": defaultTargetPlatform,
        },
      );
}
