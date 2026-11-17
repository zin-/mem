import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:mem/features/logger/log_service.dart';

abstract class AlarmScheduler {
  Future<void> oneShotAt({
    required int id,
    required DateTime startAt,
    required Map<String, dynamic> params,
    required Function callback,
    required bool exact,
    required bool allowWhileIdle,
    required bool wakeup,
    required bool rescheduleOnReboot,
  });

  Future<void> cancel(int id);
}

class AndroidAlarmManagerWrapper implements AlarmScheduler {
  bool _started = false;

  Future<bool> _ready() async {
    if (_started) {
      return true;
    }
    _started = await AndroidAlarmManager.initialize();
    return _started;
  }

  @override
  Future<void> oneShotAt({
    required int id,
    required DateTime startAt,
    required Map<String, dynamic> params,
    required Function callback,
    required bool exact,
    required bool allowWhileIdle,
    required bool wakeup,
    required bool rescheduleOnReboot,
  }) =>
      v(
        () async {
          if (!await _ready()) {
            return;
          }
          await AndroidAlarmManager.oneShotAt(
            startAt,
            id,
            callback,
            exact: exact,
            allowWhileIdle: allowWhileIdle,
            wakeup: wakeup,
            rescheduleOnReboot: rescheduleOnReboot,
            params: params,
          );
        },
        {
          'id': id,
          'startAt': startAt,
          'params': params,
          'exact': exact,
          'allowWhileIdle': allowWhileIdle,
          'wakeup': wakeup,
          'rescheduleOnReboot': rescheduleOnReboot,
        },
      );

  @override
  Future<void> cancel(int id) => v(
        () async {
          if (!await _ready()) {
            return;
          }
          await AndroidAlarmManager.cancel(id);
        },
        {
          'id': id,
        },
      );
}
