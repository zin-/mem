import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/schedule.dart';

// FIXME uuidとかにする
typedef MemId = int?;

class Mem {
  final MemId id;

  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.id, this.name, this.doneAt, this.period);

  bool get isArchived => false;

  bool get isDone => doneAt != null;

  Mem done(DateTime when) => Mem(id, name, when, period);

  Mem undone() => Mem(id, name, null, period);

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

  Iterable<Schedule> periodSchedules(
    TimeOfDay startOfDay,
  ) =>
      v(
        () {
          return [
            Schedule.of(
              id,
              period?.start?.isAllDay == true
                  ? DateTime(
                      period!.start!.year,
                      period!.start!.month,
                      period!.start!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                  : period?.start,
              NotificationType.startMem,
            ),
            Schedule.of(
              id,
              period?.end?.isAllDay == true
                  ? DateTime(
                      period!.end!.year,
                      period!.end!.month,
                      period!.end!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                      .add(const Duration(days: 1))
                      .subtract(const Duration(minutes: 1))
                  : period?.end,
              NotificationType.endMem,
            ),
          ];
        },
        {
          'this': this,
          'startOfDay': startOfDay,
        },
      );
}
