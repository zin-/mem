import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem_service.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';

final initialMemEntity = MemEntity(name: '', doneAt: null, id: null);

final memProvider = StateNotifierProvider.family<ValueStateNotifier<MemEntity?>,
    MemEntity?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(null),
  ),
);

final editingMemProvider = StateNotifierProvider.family<
    ValueStateNotifier<MemEntity>, MemEntity, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(
      ref.watch(memProvider(memId)) ?? initialMemEntity,
    ),
  ),
);

final memItemsProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ListValueStateNotifier<MemItemEntity>(null),
  ),
);

final fetchMemByIdV2 = FutureProvider.autoDispose.family<void, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      if (memId != null && ref.read(memProvider(memId)) == null) {
        final mem = await MemRepository().shipById(memId);

        ref.read(memProvider(memId).notifier).updatedBy(mem);
      }
    },
  ),
);

final fetchMemItemByMemIdV2 = FutureProvider.autoDispose.family<void, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      if (memId != null && ref.read(memItemsProvider(memId)) == null) {
        final memItems = await MemItemRepository().shipByMemId(memId);

        ref.read(memItemsProvider(memId).notifier).updatedBy(memItems);
      }
    },
  ),
);

final createMem = Provider.autoDispose.family<Future<MemEntity>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItemEntities = ref.read(memItemsProvider(memId)) ?? [];
      final editingMemEntity = ref.watch(editingMemProvider(memId));
      final memDetail = MemDetail(editingMemEntity, memItemEntities);

      final received = await MemService().create(memDetail);

      ref.read(memProvider(null).notifier).updatedBy(received.memEntity);
      ref
          .read(memItemsProvider(null).notifier)
          .updatedBy(received.memItemEntities);
      ref
          .read(memProvider(received.memEntity.id).notifier)
          .updatedBy(received.memEntity);
      ref
          .read(memItemsProvider(received.memEntity.id).notifier)
          .updatedBy(received.memItemEntities);

      return received.memEntity;
    },
  ),
);

final updateMem = Provider.autoDispose.family<Future<MemEntity>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItemEntities = ref.read(memItemsProvider(memId)) ?? [];
      final editingMemEntity = ref.watch(editingMemProvider(memId));
      final memDetail = MemDetail(editingMemEntity, memItemEntities);

      final updated = await MemService().update(memDetail);

      ref
          .read(memProvider(updated.memEntity.id).notifier)
          .updatedBy(updated.memEntity);
      ref
          .read(memItemsProvider(updated.memEntity.id).notifier)
          .updatedBy(updated.memItemEntities);

      return updated.memEntity;
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

        ref
            .read(memProvider(archived.memEntity.id).notifier)
            .updatedBy(archived.memEntity);
        ref
            .read(memItemsProvider(archived.memEntity.id).notifier)
            .updatedBy(archived.memItemEntities);

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
            .read(memProvider(unarchived.memEntity.id).notifier)
            .updatedBy(unarchived.memEntity);
        ref
            .read(memItemsProvider(unarchived.memEntity.id).notifier)
            .updatedBy(unarchived.memItemEntities);

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
