import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/acts/list_item/states.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

final startActV2 = Provider.autoDispose.family<Act, int>(
  (ref, memId) => v(
    () {
      final startingAct = Act(memId, DateAndTimePeriod.startNow());

      ActService().startV2(startingAct).then((startedAct) => v(
            () => ref.read(actsProvider.notifier).upsertAll(
              [startedAct],
              (tmp, item) => tmp.id == item.id,
            ),
            startedAct,
          ));

      return startingAct;
    },
    memId,
  ),
);

final startAct = Provider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final started = await ActService().startBy(memId);

      ref.read(actsProvider.notifier).add(started);
      ref.read(activeActsProvider.notifier).add(started);
    },
    memId,
  ),
);

final finishActV2 = Provider.autoDispose.family<Act, int>(
  (ref, memId) => v(
    () {
      final finishingAct = ref.read(activeActsProvider)!.singleWhere(
            (act) => act.memId == memId,
          );

      ActService().finish(finishingAct).then((finishedAct) => v(
            () => ref.read(actsProvider.notifier).upsertAll(
              [finishedAct],
              (tmp, item) => tmp.id == item.id,
            ),
            finishedAct,
          ));

      return finishingAct;
    },
    memId,
  ),
);

final finishAct = Provider.autoDispose.family<void, Act>(
  (ref, act) => v(
    () async {
      final finished = await ActService().finish(act);

      ref.read(actsProvider.notifier).upsertAll(
        [finished],
        (tmp, item) => tmp.id == item.id,
      );
    },
    act,
  ),
);

final editAct = Provider.autoDispose.family<Act, ActIdentifier>(
  (ref, actIdentifier) => v(
    () {
      final editingAct = ref.watch(editingActProvider(actIdentifier));

      ActService()
          .edit(editingAct)
          .then((editedAct) => ref.read(actsProvider.notifier).upsertAll(
                [editedAct],
                (tmp, item) => tmp.id == item.id,
              ));

      return editingAct;
    },
    actIdentifier,
  ),
);

final deleteAct = Provider.autoDispose.family<void, ActIdentifier>(
  (ref, actIdentifier) => v(
    () async {
      ActService().delete(actIdentifier.actId).then((value) {
        ref
            .read(actsProvider.notifier)
            .removeWhere((item) => item.id == value.id);
      });
    },
    actIdentifier,
  ),
);
