import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification.dart';

class Mem {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.name, this.doneAt, this.period);

  bool get isArchived => false;

  bool get isDone => doneAt != null;

  Mem done(DateTime when) => Mem(name, when, period);

  Mem undone() => Mem(name, null, period);

  DateTime? notifyAt(
    DateTime startOfToday,
    Iterable<MemNotification>? memNotifications,
    Act? latestAct,
  ) =>
      v(
        () => _selectNonNullOrGreater(
          period?.start != null || period?.end != null
              ? period?.start != null && period?.end != null
                  ? period!.start!.compareTo(startOfToday) < 0
                      ? period?.end
                      : period?.start
                  : period?.start ?? period?.end
              : null,
          memNotifications
                      ?.where(
                        (e) => !e.isAfterActStarted(),
                      )
                      .isEmpty ??
                  true
              ? null
              : MemNotification.nextNotifyAt(
                  memNotifications!,
                  startOfToday,
                  latestAct,
                ),
        ),
        {
          'this': this,
          'startOfToday': startOfToday,
          'memNotifications': memNotifications,
          'latestAct': latestAct,
        },
      );

  DateTime? _selectNonNullOrGreater(
    DateTime? a,
    DateTime? b,
  ) =>
      v(
        () {
          if (a != null || b != null) {
            if (a == null) {
              return b;
            } else if (b == null) {
              return a;
            } else if (a.compareTo(b) > 0) {
              return a;
            } else {
              return b;
            }
          }
          return null;
        },
        {
          'a': a,
          'b': b,
        },
      );
}
