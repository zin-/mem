import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/logger/log_service.dart';

class AndroidAlarmManagerWrapper {
  static AndroidAlarmManagerWrapper? _instance;
  bool _initialized = false;

  AndroidAlarmManagerWrapper._();

  factory AndroidAlarmManagerWrapper() => v(
        () => _instance ??= AndroidAlarmManagerWrapper._(),
        {"_instance": _instance},
      );

  static void resetSingleton() {
    _instance?._initialized = false;
    _instance = null;
  }

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
    Future<void> Function(int, Map<String, dynamic>) callback,
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
