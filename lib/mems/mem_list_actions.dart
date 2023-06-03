import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_detail_states.dart';
import 'package:mem/mems/mem_service.dart';

// TODO move
final undoRemoveMem = Provider.autoDispose.family<void, int>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final editingMem = ref.watch(editingMemProvider(memId));
      final memItems = ref.read(memItemsProvider(memId)) ?? [];
      final memDetail = MemDetail(editingMem, memItems);

      final received = await MemService().save(memDetail, undo: true);

      ref.read(memProvider(received.mem.id).notifier).updatedBy(received.mem);
      ref
          .read(memItemsProvider(received.mem.id).notifier)
          .updatedBy(received.memItems);
    },
  ),
);
