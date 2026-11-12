import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/features/mems/count_target.dart';
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
