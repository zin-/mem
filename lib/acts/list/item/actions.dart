import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

final _actsClient = ActsClient();

final editAct = Provider.autoDispose.family<Act, int>(
  (ref, actId) => v(
    () {
      final editingAct = ref.watch(editingActProvider(actId));

      _actsClient
          .edit(editingAct)
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
      _actsClient.delete(actId).then((value) {
        ref
            .read(actsProvider.notifier)
            .removeWhere((item) => item.id == value.id);
      });
    },
    actId,
  ),
);
