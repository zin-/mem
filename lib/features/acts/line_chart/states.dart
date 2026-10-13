import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';

enum Period { aDay, aWeek, aMonth, threeMonth, aYear, all }

extension PeriodExt on Period {
  DateAndTimePeriod? toPeriod(
    DateAndTime now,
    TimeOfDay startOfDay, {
    int offset = 0,
  }) =>
      v(
        () {
          if (this == Period.all) return null;

          final timeOfNow = TimeOfDay.fromDateTime(now);
          final base = DateAndTime(
            now.year,
            now.month,
            now.day - (timeOfNow.isBefore(startOfDay) ? 1 : 0),
            startOfDay.hour,
            startOfDay.minute,
          );

          late final DateAndTime start;
          late final DateAndTime end;

          switch (this) {
            case Period.aDay:
              start = base.add(Duration(days: offset));
              end = start.add(const Duration(days: 1));
            case Period.aWeek:
              var monday = base;
              while (monday.weekday != DateTime.monday) {
                monday = monday.subtract(const Duration(days: 1));
              }
              start = monday.add(Duration(days: DateTime.daysPerWeek * offset));
              end = start.add(const Duration(days: DateTime.daysPerWeek));
            case Period.aMonth:
              start = DateAndTime(
                base.year,
                base.month + offset,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
              end = DateAndTime(
                base.year,
                base.month + offset + 1,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
            case Period.threeMonth:
              // 直近3カレンダー月（例: 10月なら 8/1–11/1）
              final endMonth = base.month + 1 + offset * 3;
              end = DateAndTime(
                base.year,
                endMonth,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
              start = DateAndTime(
                base.year,
                endMonth - 3,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
            case Period.aYear:
              start = DateAndTime(
                base.year + offset,
                1,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
              end = DateAndTime(
                base.year + offset + 1,
                1,
                1,
                startOfDay.hour,
                startOfDay.minute,
              );
// coverage:ignore-start
            case Period.all:
              throw UnimplementedError();
// coverage:ignore-end
          }

          return DateAndTimePeriod(start: start, end: end);
        },
        {
          'now': now,
          'startOfDay': startOfDay,
          'offset': offset,
        },
      );
}
