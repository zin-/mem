import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_service.dart';

final loadMemItems = Provider.autoDispose.family<Future<List<MemItem>>, int?>(
  (ref, memId) => v(
    () async {
      List<MemItem> memItems = [];

      if (memId != null) {
        memItems = await MemService().fetchMemItemsByMemId(memId);
      }

      if (memItems.isEmpty) {
        memItems = [
          MemItem(memId: memId, type: MemItemType.memo, value: ''),
        ];
      }

      return memItems;
    },
    memId,
  ),
);

final saveMem =
    Provider.autoDispose.family<Future<MemDetail>, int?>((ref, memId) => v(
          () async {
            final saved = await MemService().save(
              MemDetail(
                ref.read(editingMemProvider(memId)),
                ref.read(memItemsProvider(memId)) ?? [],
              ),
            );

            ref.read(editingMemProvider(memId).notifier).updatedBy(saved.mem);
            ref
                .read(memItemsProvider(memId).notifier)
                .updatedBy(saved.memItems);
            if (memId == null) {
              ref
                  .read(editingMemProvider(saved.mem.id).notifier)
                  .updatedBy(saved.mem);
              ref
                  .read(memItemsProvider(saved.mem.id).notifier)
                  .updatedBy(saved.memItems);
            }

            ref
                .read(rawMemListProvider.notifier)
                .upsertAll([saved.mem], (tmp, item) => tmp.id == item.id);

            return saved;
          },
          memId,
        ));

final archiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(editingMemProvider(memId));

      final archived = await MemService().archive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(archived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([archived.mem], (tmp, item) => tmp.id == item.id);

      return archived;
    },
    {'memId': memId},
  ),
);

final unarchiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(editingMemProvider(memId));

      final unarchived = await MemService().unarchive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(unarchived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([unarchived.mem], (tmp, item) => tmp.id == item.id);

      return unarchived;
    },
    {'memId': memId},
  ),
);

final removedMemProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<Mem?>(null),
    memId,
  ),
);
final removedMemItemsProvider = StateNotifierProvider.family<
    ValueStateNotifier<List<MemItem>?>, List<MemItem>?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<List<MemItem>?>(null),
    memId,
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final removeSuccess = await MemService().remove(memId);

        ref.read(removedMemProvider(memId).notifier).updatedBy(
              ref
                  .read(memListProvider)
                  .firstWhere((element) => element.id == memId),
            );
        ref.read(removedMemItemsProvider(memId).notifier).updatedBy(
              ref.read(memItemsProvider(memId)),
            );

        ref
            .read(rawMemListProvider.notifier)
            .removeWhere((element) => element.id == memId);

        return removeSuccess;
      }

      return false;
    },
    memId,
  ),
);
