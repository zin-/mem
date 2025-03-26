import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

enum Period { aWeek, aMonth, threeMonth, aYear, all }

extension PeriodExt on Period {
  DateAndTimePeriod? toPeriod(
    DateAndTime now,
    TimeOfDay startOfDay,
  ) =>
      v(
        () {
          final timeOfNow = TimeOfDay.fromDateTime(now);
          DateAndTime start;
          if (timeOfNow.isBefore(startOfDay)) {
            start = DateAndTime(
              now.year,
              now.month,
              now.day - 1,
              startOfDay.hour,
              startOfDay.minute,
            );
          } else {
            start = DateAndTime(
              now.year,
              now.month,
              now.day,
              startOfDay.hour,
              startOfDay.minute,
            );
          }

          switch (this) {
            case Period.aWeek:
              while (start.weekday != DateTime.monday) {
                start = start.subtract(Duration(days: 1));
              }
            case Period.aMonth:
              while (start.day != 1) {
                start = start.subtract(Duration(days: 1));
              }
            case Period.threeMonth:
              while (start.day != 1) {
                start = start.subtract(Duration(days: 1));
              }
            case Period.aYear:
              while (start.day != 1) {
                start = start.subtract(Duration(days: 1));
              }
            case Period.all:
              return null;
          }

          return DateAndTimePeriod(
            start: start,
            end: start.add(
              Duration(
                  days: switch (this) {
                Period.aWeek => DateTime.daysPerWeek,
                Period.aMonth => DateTime.daysPerWeek * 4,
                Period.threeMonth => DateTime.daysPerWeek * 12,
                Period.aYear => DateTime.daysPerWeek * 52,
                Period.all => throw UnimplementedError(),
              }),
            ),
          );
        },
        {
          'now': now,
          'startOfDay': startOfDay,
        },
      );
}
