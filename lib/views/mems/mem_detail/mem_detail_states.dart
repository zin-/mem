import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/services/mem_service.dart';
import 'package:mem/views/atoms/state_notifier.dart';

final initialMem = Mem(name: '');

final memProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(null),
  ),
);

final editingMemProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(
      ref.watch(memProvider(memId)) ?? initialMem.copied(),
    ),
  ),
);

final memItemsProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItem>, List<MemItem>?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ListValueStateNotifier<MemItem>(null),
  ),
);

final fetchMemById = FutureProvider.autoDispose.family<void, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      if (memId != null && ref.read(memProvider(memId)) == null) {
        final mem = await MemService().fetchMemById(memId);

        ref.read(memProvider(memId).notifier).updatedBy(mem);
      }
    },
  ),
);

final loadMemItems = FutureProvider.autoDispose.family<Iterable<MemItem>, int?>(
  (ref, memId) => v(
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

final createMem = Provider.autoDispose.family<Future<Mem>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItems = ref.read(memItemsProvider(memId)) ?? [];
      final editingMem = ref.watch(editingMemProvider(memId));
      final memDetail = MemDetail(editingMem, memItems);

      final received = await MemService().save(memDetail);

      ref.read(memProvider(null).notifier).updatedBy(received.mem);
      ref.read(memItemsProvider(null).notifier).updatedBy(received.memItems);
      ref.read(memProvider(received.mem.id).notifier).updatedBy(received.mem);
      ref
          .read(memItemsProvider(received.mem.id).notifier)
          .updatedBy(received.memItems);

      return received.mem;
    },
  ),
);

final updateMem = Provider.autoDispose.family<Future<Mem>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItems = ref.read(memItemsProvider(memId)) ?? [];
      final editingMem = ref.watch(editingMemProvider(memId));
      final memDetail = MemDetail(editingMem, memItems);

      final updated = await MemService().save(memDetail);

      ref.read(memProvider(updated.mem.id).notifier).updatedBy(updated.mem);
      ref
          .read(memItemsProvider(updated.mem.id).notifier)
          .updatedBy(updated.memItems);

      return updated.mem;
    },
  ),
);

final archiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final mem = ref.read(memProvider(memId));

      if (mem == null) {
        return null;
      } else {
        final archived = await MemService().archive(mem);

        ref.read(memProvider(archived.mem.id).notifier).updatedBy(archived.mem);
        ref
            .read(memItemsProvider(archived.mem.id).notifier)
            .updatedBy(archived.memItems);

        return archived;
      }
    },
  ),
);

final unarchiveMem = Provider.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final mem = ref.read(memProvider(memId));

      if (mem == null) {
        return null;
      } else {
        final unarchived = await MemService().unarchive(mem);

        ref
            .read(memProvider(unarchived.mem.id).notifier)
            .updatedBy(unarchived.mem);
        ref
            .read(memItemsProvider(unarchived.mem.id).notifier)
            .updatedBy(unarchived.memItems);

        return unarchived;
      }
    },
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async => await MemService().remove(memId!),
  ),
);
