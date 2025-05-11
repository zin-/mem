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
          DateAndTime start = DateAndTime(
            now.year,
            now.month,
            now.day - (timeOfNow.isBefore(startOfDay) ? 1 : 0),
            startOfDay.hour,
            startOfDay.minute,
          );

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
              start = start.subtract(Duration(days: DateTime.daysPerWeek * 11));
              while (start.day != 1) {
                start = start.subtract(Duration(days: 1));
              }
            case Period.aYear:
              start = start.subtract(Duration(days: DateTime.daysPerWeek * 51));
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
// coverage:ignore-start
                Period.all => throw UnimplementedError(),
// coverage:ignore-end
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

enum AggregationType { count, sum }
