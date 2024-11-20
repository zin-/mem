import 'package:flutter/material.dart'; // FIXME coreからflutterへの依存は排除したい

import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/mems/mem_entity.dart';

class Mem {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.name, this.doneAt, this.period);

  bool get isArchived => false;

  bool get isDone => doneAt != null;

  int compareTo(
    Mem other,
    DateTime startOfToday, {
    Act? latestActOfThis,
    Act? latestActOfOther,
    Iterable<MemNotification>? memNotificationsOfThis,
    Iterable<MemNotification>? memNotificationsOfOther,
  }) =>
      v(
        () {
          if (isArchived != other.isArchived) {
            return isArchived ? 1 : -1;
          }
          if (isDone != other.isDone) {
            return isDone ? 1 : -1;
          }

          final timeOfThis = _selectNonNullOrGreater(
            period?.start != null || period?.end != null
                ? period?.start != null && period?.end != null
                    ? period!.start!.compareTo(startOfToday) < 0
                        ? period?.end
                        : period?.start
                    : period?.start ?? period?.end
                : null,
            memNotificationsOfThis
                        ?.where(
                          (e) => !e.isAfterActStarted(),
                        )
                        .isEmpty ??
                    true
                ? null
                : MemNotification.nextNotifyAt(
                    memNotificationsOfThis!,
                    startOfToday,
                    latestActOfThis,
                  ),
          );
          final timeOfOther = _selectNonNullOrGreater(
            other.period?.start != null || other.period?.end != null
                ? other.period?.start != null && other.period?.end != null
                    ? other.period!.start!.compareTo(startOfToday) < 0
                        ? other.period?.end
                        : other.period?.start
                    : other.period?.start ?? other.period?.end
                : null,
            memNotificationsOfOther
                        ?.where(
                          (e) => !e.isAfterActStarted(),
                        )
                        .isEmpty ??
                    true
                ? null
                : MemNotification.nextNotifyAt(
                    memNotificationsOfOther!,
                    startOfToday,
                    latestActOfOther,
                  ),
          );

          if (timeOfThis != null || timeOfOther != null) {
            if (timeOfThis == null) {
              return 1;
            } else if (timeOfOther == null) {
              return -1;
            } else {
              return timeOfThis.compareTo(timeOfOther);
            }
          }

          final thisHasAfterActStarted = memNotificationsOfThis
                  ?.where(
                    (e) => e.isAfterActStarted(),
                  )
                  .isNotEmpty ??
              false;
          final otherHasAfterActStarted = memNotificationsOfOther
                  ?.where(
                    (e) => e.isAfterActStarted(),
                  )
                  .isNotEmpty ??
              false;
          if (thisHasAfterActStarted != otherHasAfterActStarted) {
            return thisHasAfterActStarted ? -1 : 1;
          }

          return 0;
        },
        {
          'this': this,
          'other': other,
          'thisLatestAct': latestActOfThis,
          'otherLatestAct': latestActOfOther,
          'memNotificationsOfThis': memNotificationsOfThis,
          'memNotificationsOfOther': memNotificationsOfOther,
          'startOfToday': startOfToday,
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
          final id =
              this is SavedMemEntity ? (this as SavedMemEntity).id : null;

          return id == null
              ? throw Exception() // coverage:ignore-line
              : [
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
