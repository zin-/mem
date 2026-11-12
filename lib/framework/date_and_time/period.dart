import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

enum Period {
  aDay,
  aWeek,
  aMonth,
  threeMonth,
  aYear,
  all;

  int? get months => switch (this) {
        Period.aMonth => 1,
        Period.threeMonth => 3,
        Period.aYear => DateTime.monthsPerYear,
        Period.aDay || Period.aWeek || Period.all => null,
      };

  DateAndTime exclusiveEnd(DateTime start) {
    final day = DateAndTime(start.year, start.month, start.day);
    return switch (this) {
      Period.aDay => day.shiftCalendarDays(1),
      Period.aWeek => day.shiftCalendarDays(DateTime.daysPerWeek),
      Period.aMonth || Period.threeMonth || Period.aYear => DateAndTime(
          start.year,
          start.month + months!,
          1,
        ),
      Period.all => throw ArgumentError(this),
    };
  }
}

extension PeriodExt on Period {
  bool isLongerThan(Period other) => index > other.index;

  WithStartAndEnd? toPeriod(
    DateAndTime now,
    TimeOfDay startOfDay, {
    int offset = 0,
  }) =>
      v(
        () {
          DateAndTime at(int year, int month, int day) =>
              DateTime(year, month, day).atStartOfDay(startOfDay);

          final day = now.logicalDay(startOfDay);
          final base = at(day.year, day.month, day.day);

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

          WithStartAndEnd trailingDays(int days) {
            final inclusiveEnd = base.shiftCalendarDays(days * offset);
            final end = inclusiveEnd.shiftCalendarDays(1);
            return WithStartAndEnd(end.shiftCalendarDays(-days), end);
          }

          WithStartAndEnd trailingMonths(int months) {
            final inclusiveEnd = shiftMonths(base, months * offset);
            return WithStartAndEnd(
              shiftMonths(inclusiveEnd, -months).shiftCalendarDays(1),
              inclusiveEnd.shiftCalendarDays(1),
            );
          }

          switch (this) {
            case Period.aDay:
              return trailingDays(1);
            case Period.aWeek:
              return trailingDays(DateTime.daysPerWeek);
            case Period.aMonth:
            case Period.threeMonth:
            case Period.aYear:
              return trailingMonths(months!);
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
