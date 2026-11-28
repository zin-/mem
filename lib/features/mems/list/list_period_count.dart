import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

class ListPeriodCount {
  final int value;

  ListPeriodCount._(this.value);

  static ListPeriodCount? of({
    required Target? target,
    required int value,
  }) {
    if (CountTarget.of(target, 0) == null) return null;
    return ListPeriodCount._(value);
  }

  static DateAndTimePeriod? period({
    required Target target,
    required Act? latestAct,
    Act? scheduleAnchorAct,
    required TimeOfDay startOfDay,
    required DateTime now,
  }) {
    if (target.period == Period.aDay) {
      return Period.aDay.toPeriod(
        DateAndTime.from(now, timeOfDay: now),
        startOfDay,
      );
    }
    if (target.period == Period.aWeek) {
      return CountReferenceAct.of(
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      )?.week(now, startOfDay);
    }
    return null;
  }
}

class ListPeriodWindow {
  final DateAndTimePeriod period;
  final List<int> memIds = [];

  ListPeriodWindow._(this.period);
}

class ListPeriodWindows {
  final List<ListPeriodWindow> groups;

  ListPeriodWindows._(this.groups);

  static ListPeriodWindows of({
    required Iterable<MemEntity> mems,
    required TimeOfDay startOfDay,
    required DateTime now,
  }) {
    final byWindow = <({DateTime start, DateTime end}), ListPeriodWindow>{};
    for (final mem in mems) {
      final countTarget = CountTarget.of(mem.target, 0);
      if (countTarget == null) continue;
      final period = ListPeriodCount.period(
        target: countTarget.target,
        latestAct: mem.latestAct,
        scheduleAnchorAct: mem.scheduleAnchorAct,
        startOfDay: startOfDay,
        now: now,
      );
      if (period is! WithStartAndEnd) continue;
      final window = byWindow.putIfAbsent(
        (start: period.start, end: period.end),
        () => ListPeriodWindow._(period),
      );
      window.memIds.add(mem.id);
    }
    return ListPeriodWindows._(byWindow.values.toList());
  }

  Map<int, int> countsOf(Iterable<Act> acts) {
    final periodByMemId = <int, DateAndTimePeriod>{
      for (final group in groups)
        for (final memId in group.memIds) memId: group.period,
    };
    final counts = {
      for (final memId in periodByMemId.keys) memId: 0,
    };
    for (final act in acts) {
      if (act.isSkipped) continue;
      final period = periodByMemId[act.memId];
      if (period == null) continue;
      final start = act.period?.start;
      if (start == null || !period.includesStart(start)) continue;
      counts[act.memId] = counts[act.memId]! + 1;
    }
    return counts;
  }
}
