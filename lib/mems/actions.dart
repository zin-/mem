import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_item_entity.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removedMemDetail = ref.watch(removedMemDetailProvider(memId));

      if (removedMemDetail != null) {
        final removeUndone =
            await MemService().save(removedMemDetail, undo: true);
        final removeUndoneMem = removeUndone.mem;

        if (removeUndoneMem is SavedMemV1) {
          ref.read(memsProvider.notifier).add(removeUndoneMem);
          for (var element in removeUndone.memItems) {
            ref.read(memItemsProvider.notifier).upsertAll(
              [
                element,
              ],
              (current, updating) =>
                  current is SavedMemItemEntity &&
                  updating is SavedMemItemEntity &&
                  current.id == updating.id,
            );
          }
        }
      }
    },
    memId,
  ),
);
