import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_act_amount.g.dart';

class DayActAmount {
  final int count;
  final Duration recorded;

  const DayActAmount(this.count, this.recorded);
}

@riverpod
Future<DayActAmount> viewedDayActAmount(Ref ref, int memId, DateTime day) => v(
      () async {
        ref.watch(
          actEntitiesProvider.select((acts) => revisionOfMemActs(acts, memId)),
        );
        final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
        final amount = await ActQueryService().amountByMemIdAndPeriod(
          memId,
          day.dayPeriod(startOfDay),
        );
        return DayActAmount(amount.count, amount.recorded);
      },
      {
        'memId': memId,
        'day': day,
      },
    );
