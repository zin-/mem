import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

class ActListGroup {
  final Period unit;
  final DateTime? start;
  final WithStartAndEnd? period;

  ActListGroup._(this.unit, this.start, this.period);

  static ActListGroup? of({
    required Period unit,
    required DateTime at,
    required TimeOfDay startOfDay,
  }) {
    if (unit == Period.all) {
      return ActListGroup._(unit, null, null);
    }
    final start = _bucketStart(unit, _logicalDay(at, startOfDay));
    if (start == null) return null;
    return ActListGroup._(
      unit,
      start,
      _queryPeriod(unit, start, startOfDay),
    );
  }

  bool contains(DateTime at) => period?.includesStart(at) ?? true;

  bool isCurrentDay(DateTime at) => unit == Period.aDay && contains(at);

  String label(MaterialLocalizations localizations) {
    final start = this.start;
    final period = this.period;
    if (start == null || period == null) {
      return unit.name;
    }
    return switch (unit) {
      Period.aDay => localizations.formatCompactDate(start),
      Period.aWeek ||
      Period.threeMonth =>
        period.formatCompactRange(localizations),
      Period.aMonth => localizations.formatMonthYear(start),
      Period.aYear => localizations.formatYear(start),
      Period.all => unit.name,
    };
  }

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
    final monthsInQuarter = Period.threeMonth.months!;
    final monthsBefore = month - DateTime.january;
    return (monthsBefore ~/ monthsInQuarter) * monthsInQuarter +
        DateTime.january;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static WithStartAndEnd _queryPeriod(
    Period unit,
    DateTime start,
    TimeOfDay startOfDay,
  ) {
    final end = unit.exclusiveEnd(start);
    return WithStartAndEnd(
      start.atStartOfDay(startOfDay),
      end.atStartOfDay(startOfDay),
    );
  }
}
