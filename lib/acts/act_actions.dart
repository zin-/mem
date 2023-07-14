import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

final actRepository = ActRepository();

Future<List<Act>> fetchByMemIdIs(MemId memId) =>
    actRepository.shipByMemId(memId);

final startAct = Provider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final started = await ActService().startBy(memId);

      ref.read(actListProvider(memId).notifier).add(started, index: 0);
      ref.read(activeActsProvider.notifier).add(started);
    },
    memId,
  ),
);

final finishAct = Provider.autoDispose.family<void, Act>(
  (ref, act) => v(
    () async {
      // TODO 終了したときに、通知を消す
      final replaced = await actRepository.replace(
        Act(
          act.memId,
          DateAndTimePeriod(
            start: act.period.start,
            end: DateAndTime.now(),
          ),
          id: act.id,
        ),
      );

      ref
          .read(actListProvider(replaced.memId).notifier)
          .upsertAll([replaced], (tmp, item) => tmp.id == item.id);
      ref.read(activeActsProvider.notifier).removeWhere(
            (item) => item.id == replaced.id,
          );
    },
    act,
  ),
);

Future<Act> save(Act act) => v(
      () => actRepository.replace(act),
      act,
    );

final deleteAct = Provider.autoDispose.family<void, ActIdentifier>(
  (ref, actIdentifier) => v(
    () async {
      await ActRepository().wasteById(actIdentifier.id);

      ref
          .read(actListProvider(actIdentifier.memId).notifier)
          .removeWhere((item) => item.id == actIdentifier.id);
    },
    actIdentifier,
  ),
);
