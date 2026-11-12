import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

class ActListGroup {
  static const units = <Period>[
    Period.aDay,
    Period.aWeek,
    Period.aMonth,
    Period.threeMonth,
    Period.aYear,
  ];

  static const _monthsInQuarter = 3;

  final Period unit;
  final DateTime start;
  final WithStartAndEnd period;

  ActListGroup._(this.unit, this.start, this.period);

  static ActListGroup? of({
    required Period unit,
    required DateTime at,
    required TimeOfDay startOfDay,
  }) {
    final start = _bucketStart(unit, _logicalDay(at, startOfDay));
    if (start == null) return null;
    return ActListGroup._(
      unit,
      start,
      _queryPeriod(unit, start, startOfDay),
    );
  }

  bool contains(DateTime at) => period.includesStart(at);

  bool isCurrentDay(DateTime at) => unit == Period.aDay && contains(at);

  String label(MaterialLocalizations localizations) => switch (unit) {
        Period.aDay => localizations.formatCompactDate(start),
        Period.aWeek ||
        Period.threeMonth =>
          period.formatCompactRange(localizations),
        Period.aMonth => localizations.formatMonthYear(start),
        Period.aYear => localizations.formatYear(start),
        Period.all => localizations.formatYear(start),
      };

  @override
  bool operator ==(Object other) =>
      other is ActListGroup && other.unit == unit && other.start == start;

  @override
  int get hashCode => Object.hash(unit, start);

  static DateTime _logicalDay(DateTime at, TimeOfDay startOfDay) {
    final timed = at is DateAndTime ? at : DateAndTime.from(at, timeOfDay: at);
    final day = timed.logicalDay(startOfDay);
    return DateTime(day.year, day.month, day.day);
  }

  static DateTime? _bucketStart(Period unit, DateTime day) {
    final date = DateAndTime(day.year, day.month, day.day);
    return switch (unit) {
      Period.aDay => DateTime(date.year, date.month, date.day),
      Period.aWeek => _dateOnly(
          date.shiftCalendarDays(DateTime.monday - date.weekday),
        ),
      Period.aMonth => DateTime(date.year, date.month),
      Period.threeMonth => DateTime(
          date.year,
          _quarterStartMonth(date.month),
        ),
      Period.aYear => DateTime(date.year),
      Period.all => null,
    };
  }

  static int _quarterStartMonth(int month) {
    final monthsBefore = month - DateTime.january;
    return (monthsBefore ~/ _monthsInQuarter) * _monthsInQuarter +
        DateTime.january;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static WithStartAndEnd _queryPeriod(
    Period unit,
    DateTime start,
    TimeOfDay startOfDay,
  ) {
    final day = DateAndTime(start.year, start.month, start.day);
    final end = switch (unit) {
      Period.aDay => day.shiftCalendarDays(1),
      Period.aWeek => day.shiftCalendarDays(DateTime.daysPerWeek),
      Period.aMonth => DateAndTime(start.year, start.month + 1, 1),
      Period.threeMonth => DateAndTime(
          start.year,
          start.month + _monthsInQuarter,
          1,
        ),
      Period.aYear => DateAndTime(start.year + 1, DateTime.january, 1),
      Period.all => throw ArgumentError(unit),
    };
    return WithStartAndEnd(
      _atStartOfDay(start, startOfDay),
      _atStartOfDay(end, startOfDay),
    );
  }

  static DateAndTime _atStartOfDay(DateTime day, TimeOfDay startOfDay) =>
      DateAndTime(
        day.year,
        day.month,
        day.day,
        startOfDay.hour,
        startOfDay.minute,
      );
}
