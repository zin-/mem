import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'period_act_count.g.dart';

@riverpod
Future<CountTarget?> periodActCount(Ref ref, int memId) => v(
      () async {
        // 集計前なので count は仮。正の件数目標のときだけ Target を残す
        final target = ref.watch(
          targetsProvider.select(
            (targets) => CountTarget.of(
              targets.where((e) => e.value.memId == memId).firstOrNull?.value,
              0,
            )?.target,
          ),
        );
        if (target == null) {
          return null;
        }

        // select は == で間引く。List は毎回別インスタンスなので、
        // 件数に効く項目だけ hash して int にする
        ref.watch(
          actEntitiesProvider.select((acts) => revisionOfMemActs(acts, memId)),
        );

        final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
        return CountTarget.of(
          target,
          await ActQueryService().countByMemIdAndPeriod(
            memId,
            target.period.toPeriod(DateAndTime.now(), startOfDay),
          ),
        );
      },
      {
        'memId': memId,
      },
    );
