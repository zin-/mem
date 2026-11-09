import 'package:flutter/material.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

class TodayActCount {
  final Target target;
  final int value;

  TodayActCount._(this.target, this.value);

  static Future<TodayActCount?> of({
    required Target? target,
    required int memId,
    required TimeOfDay startOfDay,
    DateTime? now,
    ActQueryService? acts,
  }) =>
      v(
        () async {
          if (target == null || !target.acceptsSecondsAfterLastAct) {
            return null;
          }
          final at = now ?? DateTime.now();
          final count = await (acts ?? ActQueryService()).countByMemIdAndPeriod(
            memId,
            Period.aDay.toPeriod(
              DateAndTime.from(at, timeOfDay: at),
              startOfDay,
            ),
          );
          return TodayActCount._(target, count);
        },
        {
          'target': target,
          'memId': memId,
          'startOfDay': startOfDay,
          'now': now,
        },
      );

  static Future<TodayActCount?> forMem({
    required int memId,
    required TimeOfDay startOfDay,
    DateTime? now,
    ActQueryService? acts,
    TargetRepository? targets,
  }) =>
      v(
        () async {
          final rows = await (targets ?? TargetRepository()).shipByMemId(memId);
          if (rows.isEmpty) return null;
          return of(
            target: rows.first.toDomain(),
            memId: memId,
            startOfDay: startOfDay,
            now: now,
            acts: acts,
          );
        },
        {
          'memId': memId,
          'startOfDay': startOfDay,
          'now': now,
        },
      );

  static Future<Map<int, int>> byMemId({
    required Iterable<({int id, Target? target})> mems,
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
