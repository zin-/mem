import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

const _memIdKey = '_memId';

final memProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int?>(
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

final fetchMemById =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      var memMap = ref.read(memMapProvider(memId));

      if (memId != null && !Mem.isSavedMap(memMap)) {
        try {
          final mem = await MemRepositoryV1().shipWhereIdIs(memId);
          ref.read(memProvider(memId).notifier).updatedBy(mem);
          memMap = mem.toMap();
        } catch (e) {
          warn(e);
        }
      }

      return memMap;
    },
  ),
);

final createMem =
    Provider.autoDispose.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      memMap.remove(_memIdKey);

      final received = await MemRepositoryV1().receive(memMap);

      ref.read(memProvider(received.id).notifier).updatedBy(received);
      ref.read(memProvider(null).notifier).updatedBy(received);

      return received;
    },
  ),
);

final updateMem =
    Provider.autoDispose.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      memMap.remove(_memIdKey);

      final updated = await MemRepositoryV1().update(Mem.fromMap(memMap));

      ref.read(memProvider(updated.id).notifier).updatedBy(updated);

      return updated;
    },
  ),
);

// FIXME memMapを受け取ると変更途中で更新していない項目も受け取ってしまうのでは？
final archiveMem = Provider.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final archived = await MemRepositoryV1().archive(Mem.fromMap(memMap));
      ref.read(memProvider(archived.id).notifier).updatedBy(archived);
      return archived;
    },
  ),
);

final unarchiveMem = Provider.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final unarchived = await MemRepositoryV1().unarchive(Mem.fromMap(memMap));
      ref.read(memProvider(unarchived.id).notifier).updatedBy(unarchived);
      return unarchived;
    },
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async => await MemRepositoryV1().discardWhereIdIs(memId),
  ),
);
