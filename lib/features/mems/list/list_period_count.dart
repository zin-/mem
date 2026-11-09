import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

class ListPeriodCount {
  final int value;

  ListPeriodCount._(this.value);

  static Future<ListPeriodCount?> of({
    required Target? target,
    required int memId,
    required Act? latestAct,
    Act? scheduleAnchorAct,
    required TimeOfDay startOfDay,
    DateTime? now,
    ActQueryService? acts,
  }) =>
      v(
        () async {
          if (CountTarget.of(target, 0) == null) return null;
          final period = _period(
            target!,
            latestAct,
            scheduleAnchorAct,
            startOfDay,
            now ?? DateTime.now(),
          );
          if (period == null) return null;
          return ListPeriodCount._(
            await (acts ?? ActQueryService()).countByMemIdAndPeriod(
              memId,
              period,
            ),
          );
        },
        {
          'target': target,
          'memId': memId,
          'latestAct': latestAct,
          'scheduleAnchorAct': scheduleAnchorAct,
          'startOfDay': startOfDay,
          'now': now,
        },
      );

  static DateAndTimePeriod? _period(
    Target target,
    Act? latestAct,
    Act? scheduleAnchorAct,
    TimeOfDay startOfDay,
    DateTime now,
  ) {
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
      )?.week(startOfDay);
    }
    return null;
  }

  static Future<Map<int, int>> byMemId({
    required Iterable<
            ({
              int id,
              Target? target,
              Act? latestAct,
              Act? scheduleAnchorAct,
            })>
        mems,
    required TimeOfDay startOfDay,
    DateTime? now,
    ActQueryService? acts,
  }) =>
      v(
        () async {
          final at = now ?? DateTime.now();
          final counts = <int, int>{};
          for (final mem in mems) {
            final count = await of(
              target: mem.target,
              memId: mem.id,
              latestAct: mem.latestAct,
              scheduleAnchorAct: mem.scheduleAnchorAct,
              startOfDay: startOfDay,
              now: at,
              acts: acts,
            );
            if (count != null) {
              counts[mem.id] = count.value;
            }
          }
          return counts;
        },
        {
          'startOfDay': startOfDay,
          'now': now,
        },
      );
}
