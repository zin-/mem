import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'mem_service.dart';
import 'states.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removedMemDetail = ref.watch(removedMemDetailProvider(memId));

      if (removedMemDetail != null) {
        final removeUndone =
            await MemService().save(removedMemDetail, undo: true);

        ref.read(memEntitiesProvider.notifier).upsert(
          [removeUndone.mem as SavedMemEntityV2],
        );
        ref.read(memItemsProvider.notifier).upsertAll(
              removeUndone.memItems,
              (current, updating) =>
                  current is SavedMemItemEntityV2 &&
                  updating is SavedMemItemEntityV2 &&
                  current.id == updating.id,
            );
      }
    },
    memId,
  ),
);
