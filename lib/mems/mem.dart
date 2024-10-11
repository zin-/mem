import 'package:flutter/material.dart'; // FIXME coreからflutterへの依存は排除したい

import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/notifications/mem_notifications.dart';
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
    Mem other, {
    Act? latestActOfThis,
    Act? latestActOfOther,
    Iterable<MemNotification>? memNotificationsOfThis,
    Iterable<MemNotification>? memNotificationsOfOther,
    TimeOfDay? startOfDay,
    DateTime? now,
  }) =>
      v(
        () {
          if (isArchived != other.isArchived) {
            return isArchived ? 1 : -1;
          }
          if (isDone != other.isDone) {
            return isDone ? 1 : -1;
          }

          if (memNotificationsOfThis != null &&
              memNotificationsOfOther != null &&
              startOfDay != null &&
              now != null) {
            final comparedTime = _compareTime(
              period,
              MemNotifications.nextRepeatNotifyAt(
                memNotificationsOfThis,
                startOfDay,
                latestActOfThis,
                now,
              ),
              other.period,
              MemNotifications.nextRepeatNotifyAt(
                memNotificationsOfOther,
                startOfDay,
                latestActOfOther,
                now,
              ),
            );
            if (comparedTime != 0) {
              return comparedTime;
            }
          }

          return 0;
        },
        {
          'other': other,
          'thisLatestAct': latestActOfThis,
          'otherLatestAct': latestActOfOther,
        },
      );

  int _compareTime(
    DateAndTimePeriod? periodOfA,
    DateTime? nextNotifyAtOfA,
    DateAndTimePeriod? periodOfB,
    DateTime? nextNotifyAtOfB,
  ) =>
      v(
        () {
          if ((periodOfA == null && nextNotifyAtOfA == null) &&
              (periodOfB == null && nextNotifyAtOfB == null)) {
            return 0;
          } else if (nextNotifyAtOfA != null && nextNotifyAtOfB != null) {
            return nextNotifyAtOfA.compareTo(nextNotifyAtOfB);
          } else if (periodOfA != null && nextNotifyAtOfB != null) {
            return periodOfA.compareWithDateAndTime(nextNotifyAtOfB);
          } else if (nextNotifyAtOfA != null && periodOfB != null) {
            return -periodOfB.compareWithDateAndTime(nextNotifyAtOfA);
          } else if ((periodOfA == null && nextNotifyAtOfA == null) ||
              (periodOfB == null && nextNotifyAtOfB == null)) {
            return (periodOfA == null && nextNotifyAtOfA == null) ? 1 : -1;
          } else {
            return DateAndTimePeriod.compare(periodOfA, periodOfB);
          }
        },
        {
          'periodOfA': periodOfA,
          'nextNotifyAtOfA': nextNotifyAtOfA,
          'periodOfB': periodOfB,
          'nextNotifyAtOfB': nextNotifyAtOfB,
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
