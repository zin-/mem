import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
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
  final TimeOfDay _startOfDay;

  ActsSummary(
    this._acts,
    this._aggregationType, {
    DateAndTimePeriod? period,
    TimeOfDay startOfDay = const TimeOfDay(hour: 0, minute: 0),
  })  : _period = period,
        _startOfDay = startOfDay;

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
        .groupListsBy((e) => e.period!.start!.logicalDay(_startOfDay));

    _fillMissingDays(groupedListByDate);

    // 月は最大31日なので日ごと。3か月は約90日で表示しきれないので週にまとめる
    // 週番号は年始で 0 や翌年の 1 になり、同じ週が割れる
    final byWeek = groupedListByDate.length > 31;
    return groupedListByDate.entries
        .sorted((a, b) => a.key.compareTo(b.key))
        .groupListsBy(
          (element) => byWeek ? _weekStart(element.key) : element.key,
        )
        .map(
          (key, value) => MapEntry(
            key,
            getValue(
              value.map((e) => e.value).toList(growable: false).flattenedToList,
            ),
          ),
        );
  }

  DateAndTime _weekStart(DateAndTime day) =>
      day.shiftCalendarDays(DateTime.monday - day.weekday);

  void _fillMissingDays(Map<DateAndTime, List<Act>> grouped) {
    final start = _period?.start;
    final end = _period?.end;
    if (start != null && end != null) {
      for (final day in _calendarDays(
        DateAndTime(start.year, start.month, start.day),
        DateAndTime(end.year, end.month, end.day).shiftCalendarDays(-1),
      )) {
        grouped.putIfAbsent(day, () => []);
      }
      return;
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    for (var index = 1; index < sortedKeys.length; index++) {
      for (final day in _calendarDays(
        sortedKeys[index - 1].shiftCalendarDays(1),
        sortedKeys[index].shiftCalendarDays(-1),
      )) {
        grouped.putIfAbsent(day, () => []);
      }
    }
  }
}

Iterable<DateAndTime> _calendarDays(DateAndTime from, DateAndTime to) sync* {
  var cursor = DateAndTime(from.year, from.month, from.day);
  final last = DateAndTime(to.year, to.month, to.day);
  while (!cursor.isAfter(last)) {
    yield cursor;
    cursor = cursor.shiftCalendarDays(1);
  }
}
