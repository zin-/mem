// FIXME coreからflutterへの依存は排除したい
import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/mems/mem_entity.dart';

class Mem {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.name, this.doneAt, this.period);

  bool get isDone => doneAt != null;

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
