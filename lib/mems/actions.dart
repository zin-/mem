import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_service.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removedMem = ref.watch(removedMemProvider(memId));

      if (removedMem != null) {
        final removedMemItems = ref.read(removedMemItemsProvider(memId)) ?? [];
        final memDetail = MemDetail(removedMem, removedMemItems);

        final removeUndone = await MemService().save(memDetail, undo: true);

        ref.read(rawMemListProvider.notifier).add(removeUndone.mem);
        ref
            .read(memItemsProvider(removeUndone.mem.id).notifier)
            .updatedBy(removeUndone.memItems);
      }
    },
    memId,
  ),
);
