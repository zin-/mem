import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/i/api.dart' as v1;
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_service.dart';

final loadMemItems = FutureProvider.autoDispose.family<Iterable<MemItem>, int?>(
  (ref, memId) => v1.v(
    {'memId': memId},
    () async {
      final memItemsState = ref.read(memItemsProvider(memId));

      if (memItemsState == null) {
        final defaultMemItems = [
          MemItem(memId: memId, type: MemItemType.memo, value: ''),
        ];

        Future<List<MemItem>> memItemsFuture;
        if (memId == null) {
          memItemsFuture = Future.value(List.empty());
        } else {
          memItemsFuture = MemService().fetchMemItemsByMemId(memId);
        }

        final memItems = (await memItemsFuture).isEmpty
            ? defaultMemItems
            : await memItemsFuture;

        ref.read(memItemsProvider(memId).notifier).updatedBy(memItems);
        return memItems;
      }

      return memItemsState;
    },
  ),
);

final saveMem =
    Provider.autoDispose.family<Future<Mem>, int?>((ref, memId) => v(
          () async {
            final saved = await MemService().save(
              MemDetail(
                ref.read(editingMemProvider(memId)),
                ref.read(memItemsProvider(memId)) ?? [],
              ),
            );

            ref.read(editingMemProvider(memId).notifier).updatedBy(saved.mem);
            ref
                .read(rawMemListProvider.notifier)
                .upsertAll([saved.mem], (tmp, item) => tmp.id == item.id);

            return saved.mem;
          },
          memId,
        ));

final archiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v1.v(
    {'memId': memId},
    () async {
      final mem = ref.read(editingMemProvider(memId));

      final archived = await MemService().archive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(archived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([archived.mem], (tmp, item) => tmp.id == item.id);

      return archived;
    },
  ),
);

final unarchiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v1.v(
    {'memId': memId},
    () async {
      final mem = ref.read(editingMemProvider(memId));

      final unarchived = await MemService().unarchive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(unarchived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([unarchived.mem], (tmp, item) => tmp.id == item.id);

      return unarchived;
    },
  ),
);

final removedMem =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<Mem?>(null),
    memId,
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final removeSuccess = await MemService().remove(memId);

        ref.read(removedMem(memId).notifier).updatedBy(
              ref
                  .read(memListProvider)
                  .firstWhere((element) => element.id == memId),
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
