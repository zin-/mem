import 'package:collection/collection.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/statistics/summary_statistics.dart';

enum AggregationType {
  count,
  sum,
}

extension AggregationTypeFormat on AggregationType {
  String format(double value) {
    switch (this) {
      case AggregationType.count:
        return value.toStringAsFixed(1);
      case AggregationType.sum:
        final hours = (value / 3600).floor();
        final minutes = ((value % 3600) / 60).floor();
        final seconds = (value % 60).floor();
        return '${hours}h ${minutes}m ${seconds}s';
    }
  }
}

class ActsSummary extends SummaryStatistics {
  final Iterable<Act> _acts;
  final AggregationType _aggregationType;
  final DateAndTimePeriod? _period;

  ActsSummary(
    this._acts,
    this._aggregationType, {
    DateAndTimePeriod? period,
  }) : _period = period;

  @override
  Map<DateAndTime, double> get groupedListByDate => _groupListByDate(_acts);

  @override
  double getValue(List<dynamic> items) {
    final acts = items as List<Act>;
    switch (_aggregationType) {
      case AggregationType.count:
        return acts.length.toDouble();
      case AggregationType.sum:
        return acts
            .map((act) => act.period?.duration.inSeconds ?? 0)
            .fold(0, (sum, duration) => sum + duration)
            .toDouble();
    }
  }

  Map<DateAndTime, double> _groupListByDate(Iterable<Act> acts) {
    final groupedListByDate = acts
        .where((e) => e.period?.start != null)
        .groupListsBy((e) => DateAndTime.from(e.period!.start!));

    _fillMissingDays(groupedListByDate);

    // 1年未満は日ごと。年は点が多いので週にまとめる
    return groupedListByDate.entries
        .sorted((a, b) => a.key.compareTo(b.key))
        .groupListsBy(
          (element) => groupedListByDate.length >= 365
              ? element.key.year * 100 + element.key.weekNumber
              : element.key,
        )
        .map(
          (key, value) => MapEntry(
            value.first.key,
            getValue(
              value.map((e) => e.value).toList(growable: false).flattenedToList,
            ),
          ),
        );
  }

  void _fillMissingDays(Map<DateAndTime, List<Act>> grouped) {
    final start = _period?.start;
    final end = _period?.end;
    if (start != null && end != null) {
      final inclusiveEnd = DateTime(end.year, end.month, end.day - 1);
      for (final day in _calendarDays(
        DateAndTime(start.year, start.month, start.day),
        DateAndTime(
          inclusiveEnd.year,
          inclusiveEnd.month,
          inclusiveEnd.day,
        ),
      )) {
        grouped.putIfAbsent(day, () => []);
      }
      return;
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    for (var index = 1; index < sortedKeys.length; index++) {
      for (final day in _calendarDays(
        _shiftCalendarDays(sortedKeys[index - 1], 1),
        _shiftCalendarDays(sortedKeys[index], -1),
      )) {
        grouped.putIfAbsent(day, () => []);
      }
    }
  }
}

// local の Duration 差は DST で暦日がずれるため、日付成分で進める
Iterable<DateAndTime> _calendarDays(DateAndTime from, DateAndTime to) sync* {
  var cursor = DateTime(from.year, from.month, from.day);
  final last = DateTime(to.year, to.month, to.day);
  while (!cursor.isAfter(last)) {
    yield DateAndTime(cursor.year, cursor.month, cursor.day);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
}

DateAndTime _shiftCalendarDays(DateAndTime day, int days) {
  final shifted = DateTime(day.year, day.month, day.day + days);
  return DateAndTime(shifted.year, shifted.month, shifted.day);
}
