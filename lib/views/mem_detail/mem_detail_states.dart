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
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ListValueStateNotifier<MemItemEntity>([
      MemItemEntity(
        memId: memId,
        type: MemDetailType.memo,
        id: null,
      ),
    ]),
  ),
);

final fetchMemById =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      if (memId != null && ref.read(memProvider(memId)) == null) {
        try {
          final mem = await MemRepository().shipById(memId);
          ref.read(memProvider(memId).notifier).updatedBy(mem);
          final memItems = await MemItemRepository().shipByMemId(mem.id);
          for (var memItem in memItems) {
            ref.read(memItemsProvider(memId).notifier).update(
                  memItem,
                  (item) => item.memId == memItem.memId,
                );
          }
          return mem.toMap();
        } catch (e) {
          warn(e);
        }
      }

      return ref.read(memMapProvider(memId));
    },
  ),
);

final createMem =
    Provider.autoDispose.family<Future<MemEntity>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      memMap.remove(_memIdKey);
      final memItems = ref.read(memItemsProvider(null));

      final receivedMem = await MemService().create(memMap, memItems);

      ref.read(memProvider(receivedMem.id).notifier).updatedBy(receivedMem);
      ref.read(memProvider(null).notifier).updatedBy(receivedMem);

      return receivedMem;
    },
  ),
);

final updateMem =
    Provider.autoDispose.family<Future<MemEntity>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      memMap.remove(_memIdKey);

      final updated = await MemRepository().update(MemEntity.fromMap(memMap));

      ref.read(memProvider(updated.id).notifier).updatedBy(updated);

      return updated;
    },
  ),
);

// FIXME memMapを受け取ると変更途中で更新していない項目も受け取ってしまうのでは？
final archiveMem = Provider.family<Future<MemEntity>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final archived = await MemRepository().archive(MemEntity.fromMap(memMap));
      ref.read(memProvider(archived.id).notifier).updatedBy(archived);
      return archived;
    },
  ),
);

final unarchiveMem = Provider.family<Future<MemEntity>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final unarchived =
          await MemRepository().unarchive(MemEntity.fromMap(memMap));
      ref.read(memProvider(unarchived.id).notifier).updatedBy(unarchived);
      return unarchived;
    },
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async => await MemRepository().discardById(memId),
  ),
);
