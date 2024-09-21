// FIXME coreからflutterへの依存は排除したい
import 'package:flutter/material.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';
import 'package:mem/repositories/mem.dart';

class Mem extends EntityV1 {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.name, this.doneAt, this.period);

  bool get isDone => doneAt != null;

  factory Mem.defaultNew() => Mem("", null, null);

  Iterable<Schedule> periodSchedules(
    TimeOfDay startOfDay,
  ) =>
      v(
        () {
          final id = this is SavedMem ? (this as SavedMem).id : null;

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

  Mem copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      Mem(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      );

  @override
  String toString() => "${super.toString()}: ${{
        "name": name,
        "doneAt": doneAt,
        "period": period,
      }}";
}
