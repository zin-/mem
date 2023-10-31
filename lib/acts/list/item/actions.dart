import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

final editAct = Provider.autoDispose.family<Act, int>(
  (ref, actId) => v(
    () {
      final editingAct = ref.watch(editingActProvider(actId));

      ActService()
          .edit(SavedActV2.fromV1(editingAct))
          .then((value) => value.toV1())
          .then((editedAct) => ref.read(actsProvider.notifier).upsertAll(
                [editedAct],
                (tmp, item) => tmp.id == item.id,
              ));

      return editingAct;
    },
    actId,
  ),
);

final deleteAct = Provider.autoDispose.family<void, int>(
  (ref, actId) => v(
    () async {
      ActService().delete(actId).then((value) {
        ref
            .read(actsProvider.notifier)
            .removeWhere((item) => item.id == value.id);
      });
    },
    actId,
  ),
);
