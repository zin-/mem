import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removedMemDetail = ref.watch(removedMemDetailProvider(memId));

      if (removedMemDetail != null) {
        final removeUndone =
            await MemService().save(removedMemDetail, undo: true);

        ref.read(memsProvider.notifier).add(removeUndone.mem);
        ref
            .read(memItemsProvider(removeUndone.mem.id).notifier)
            .updatedBy(removeUndone.memItems);
      }
    },
    memId,
  ),
);
