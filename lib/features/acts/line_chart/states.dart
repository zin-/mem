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
            base = base.shiftCalendarDays(-1);
          }

          // 31日など、対象月に無い日は月末に切り詰める
          DateAndTime shiftMonths(DateAndTime date, int months) {
            final shifted = DateTime(date.year, date.month + months);
            final lastDay = DateTime(shifted.year, shifted.month + 1, 0).day;
            return at(
              shifted.year,
              shifted.month,
              date.day < lastDay ? date.day : lastDay,
            );
          }

          DateAndTimePeriod trailingDays(int days) {
            final inclusiveEnd = base.shiftCalendarDays(days * offset);
            final end = inclusiveEnd.shiftCalendarDays(1);
            return DateAndTimePeriod(
              start: end.shiftCalendarDays(-days),
              end: end,
            );
          }

          DateAndTimePeriod trailingMonths(int months) {
            final inclusiveEnd = shiftMonths(base, months * offset);
            return DateAndTimePeriod(
              start: shiftMonths(inclusiveEnd, -months).shiftCalendarDays(1),
              end: inclusiveEnd.shiftCalendarDays(1),
            );
          }

          switch (this) {
            case Period.aDay:
              return trailingDays(1);
            case Period.aWeek:
              return trailingDays(DateTime.daysPerWeek);
            case Period.aMonth:
              return trailingMonths(1);
            case Period.threeMonth:
              return trailingMonths(3);
            case Period.aYear:
              return trailingMonths(12);
            case Period.all:
              return null;
          }
        },
        {
          'now': now,
          'startOfDay': startOfDay,
          'offset': offset,
        },
      );
}

extension DateAndTimePeriodRangeFormat on DateAndTimePeriod {
  String formatCompactRange(MaterialLocalizations localizations) {
    final startLabel = localizations.formatCompactDate(start!);
    final inclusiveEnd = end!.shiftCalendarDays(-1);
    if (start!.year == inclusiveEnd.year &&
        start!.month == inclusiveEnd.month &&
        start!.day == inclusiveEnd.day) {
      return startLabel;
    }
    return '$startLabel – ${localizations.formatCompactDate(inclusiveEnd)}';
  }
}
