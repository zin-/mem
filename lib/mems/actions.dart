import 'package:mem/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'mem_item_entity.dart';
import 'mem_service.dart';
import 'states.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removedMemDetail = ref.watch(removedMemDetailProvider(memId));

      if (removedMemDetail != null) {
        final removeUndone =
            await MemService().save(removedMemDetail, undo: true);

        ref.read(memsProvider.notifier).add(removeUndone.mem);
        ref.read(memItemsProvider.notifier).upsertAll(
              removeUndone.memItems.map((e) => e.toV1()),
              (current, updating) =>
                  current is SavedMemItemEntity &&
                  updating is SavedMemItemEntity &&
                  current.id == updating.id,
            );
      }
    },
    memId,
  ),
);
