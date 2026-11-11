import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/targets/target.dart';

class ListFrameCount {
  final int value;

  ListFrameCount._(this.value);

  static ListFrameCount? of({
    required Target? target,
    required int periodCount,
    required Act? latestAct,
    Act? scheduleAnchorAct,
    required DateTime startOfToday,
    required TimeOfDay startOfDay,
  }) {
    final countTarget = CountTarget.of(target, periodCount);
    if (countTarget == null) return null;
    final shown = _shown(
      countTarget,
      latestAct,
      scheduleAnchorAct,
      startOfToday,
      startOfDay,
    );
    if (shown == null) return null;
    return ListFrameCount._(shown);
  }

  static int? _shown(
    CountTarget countTarget,
    Act? latestAct,
    Act? scheduleAnchorAct,
    DateTime startOfToday,
    TimeOfDay startOfDay,
  ) {
    final period = countTarget.target.period;
    if (period == Period.aDay) {
      return countTarget.count >= countTarget.targetValue
          ? 0
          : countTarget.count;
    }
    if (period == Period.aWeek) {
      final reference = CountReferenceAct.of(
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      );
      final withinWeek =
          reference != null && reference.isWithinWeek(startOfToday, startOfDay);
      if (!withinWeek || countTarget.count >= countTarget.targetValue) {
        return 0;
      }
      return countTarget.count;
    }
    return null;
  }
}
