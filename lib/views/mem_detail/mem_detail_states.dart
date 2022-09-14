import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem_service.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';

// FIXME 消せそう
const _memIdKey = '_memId';

final memProvider = StateNotifierProvider.family<ValueStateNotifier<MemEntity?>,
    MemEntity?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(null),
  ),
);

final memMapProvider = StateNotifierProvider.family<
    ValueStateNotifier<Map<String, dynamic>>, Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(
        (ref.watch(memProvider(memId))?.toMap() ?? {})..[_memIdKey] = memId),
  ),
);

final memItemsProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ListValueStateNotifier<MemItemEntity>(null),
  ),
);

final fetchMemById =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      try {
        if (memId != null) {
          if (ref.read(memProvider(memId)) == null) {
            final mem = await MemRepository().shipById(memId);
            ref.read(memProvider(memId).notifier).updatedBy(mem);
          }
          if (ref.read(memItemsProvider(memId)) == null) {
            final memItems = await MemItemRepository().shipByMemId(memId);
            ref.read(memItemsProvider(memId).notifier).updatedBy(memItems);
          }
        }
      } catch (e) {
        warn(e);
      }

      return ref.read(memMapProvider(memId));
    },
  ),
);

final createMem = Provider.autoDispose.family<Future<MemEntity>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItems = ref.read(memItemsProvider(memId)) ?? [];
      final memMap = ref.read(memMapProvider(memId));
      final memDetail = MemDetail(MemEntity.fromMap(memMap), memItems);

      final receivedMemDetail = await MemService().create(memDetail);

      ref
          .read(memProvider(null).notifier)
          .updatedBy(receivedMemDetail.memEntity);
      ref
          .read(memItemsProvider(null).notifier)
          .updatedBy(receivedMemDetail.memItemEntities);
      ref
          .read(memProvider(receivedMemDetail.memEntity.id).notifier)
          .updatedBy(receivedMemDetail.memEntity);
      ref
          .read(memItemsProvider(receivedMemDetail.memEntity.id).notifier)
          .updatedBy(receivedMemDetail.memItemEntities);

      return receivedMemDetail.memEntity;
    },
  ),
);

final updateMem = Provider.autoDispose.family<Future<MemEntity>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final memItemEntities = ref.read(memItemsProvider(memId)) ?? [];
      final memMap = ref.read(memMapProvider(memId));
      final memDetail = MemDetail(MemEntity.fromMap(memMap), memItemEntities);

      final updatedMemDetail = await MemService().update(memDetail);

      ref
          .read(memProvider(updatedMemDetail.memEntity.id).notifier)
          .updatedBy(updatedMemDetail.memEntity);
      ref
          .read(memItemsProvider(updatedMemDetail.memEntity.id).notifier)
          .updatedBy(updatedMemDetail.memItemEntities);

      return updatedMemDetail.memEntity;
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
