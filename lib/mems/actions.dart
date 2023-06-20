import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_service.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final editingMem = ref.watch(editingMemProvider(memId));
      final memItems = ref.read(memItemsProvider(memId)) ?? [];
      final memDetail = MemDetail(editingMem, memItems);

      final removeUndone = await MemService().save(memDetail, undo: true);

      ref.read(rawMemListProvider.notifier).add(removeUndone.mem);
      ref
          .read(memProvider(removeUndone.mem.id).notifier)
          .updatedBy(removeUndone.mem);
      ref
          .read(memItemsProvider(removeUndone.mem.id).notifier)
          .updatedBy(removeUndone.memItems);
    },
    memId,
  ),
);
