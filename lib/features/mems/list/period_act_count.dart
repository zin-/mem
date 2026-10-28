import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'period_act_count.g.dart';

class PeriodActCount {
  final int count;
  final int target;

  const PeriodActCount({required this.count, required this.target});
}

@riverpod
Future<PeriodActCount?> periodActCount(Ref ref, int memId) => v(
      () async {
        final target = ref
            .watch(targetsProvider)
            .where((e) => e.value.memId == memId)
            .firstOrNull
            ?.value;
        if (target == null ||
            target.targetUnit != TargetUnit.count ||
            target.value <= 0) {
          return null;
        }

        ref.watch(
          actEntitiesProvider.select(
            (acts) => Object.hashAll(
              acts.where((act) => act.value.memId == memId).map(
                    (act) => Object.hash(
                      act.id,
                      act.value.period?.start,
                      act.value.period?.end,
                      act.value.actKind,
                    ),
                  ),
            ),
          ),
        );

        final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
        final range = target.period.toPeriod(DateAndTime.now(), startOfDay);
        return PeriodActCount(
          count: await ActQueryService().countByMemIdAndPeriod(memId, range),
          target: target.value,
        );
      },
      {
        'memId': memId,
      },
    );
