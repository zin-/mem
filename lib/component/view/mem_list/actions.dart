import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/detail/mem_detail_states.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/mem_service.dart';

final fetchMemList = FutureProvider(
  (ref) => v(
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final mems = (await MemRepository().shipByCondition(
        showNotArchived == showArchived ? null : showArchived,
        showNotDone == showDone ? null : showDone,
      ));

      ref.read(rawMemListProvider.notifier).upsertAll(
            mems,
            (tmp, item) => tmp.id == item.id,
          );
    },
  ),
);

final undoRemoveMem = FutureProvider.family<void, int>(
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
