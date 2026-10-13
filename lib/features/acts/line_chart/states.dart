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
          DateAndTime at(int year, int month, int day) => DateAndTime(
                year,
                month,
                day,
                startOfDay.hour,
                startOfDay.minute,
              );

          var base = at(now.year, now.month, now.day);
          if (TimeOfDay.fromDateTime(now).isBefore(startOfDay)) {
            base = base.subtract(const Duration(days: 1));
          }

          final DateAndTime start;
          final DateAndTime end;

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
              start = at(base.year, base.month + offset, 1);
              end = at(base.year, base.month + offset + 1, 1);
            case Period.threeMonth:
              // 直近3カレンダー月（例: 10月なら 8/1–11/1）
              final endMonth = base.month + 1 + offset * 3;
              start = at(base.year, endMonth - 3, 1);
              end = at(base.year, endMonth, 1);
            case Period.aYear:
              start = at(base.year + offset, 1, 1);
              end = at(base.year + offset + 1, 1, 1);
            case Period.all:
              return null;
          }

          return DateAndTimePeriod(start: start, end: end);
        },
        {
          'now': now,
          'startOfDay': startOfDay,
          'offset': offset,
        },
      );

  String formatRange(
    MaterialLocalizations localizations,
    DateAndTimePeriod period,
  ) {
    final start = localizations.formatCompactDate(period.start!);
    if (this == Period.aDay) {
      return start;
    }

    final inclusiveEnd = period.end!.subtract(const Duration(days: 1));
    return '$start – ${localizations.formatCompactDate(inclusiveEnd)}';
  }
}
