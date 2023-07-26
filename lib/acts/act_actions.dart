import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final actRepository = ActRepository();

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
      final replaced = await ActService().finish(act);

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
