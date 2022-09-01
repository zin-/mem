import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

const _memIdKey = '_memId';

final memMapProvider = StateNotifierProvider.family<
    ValueStateNotifier<Map<String, dynamic>>, Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(
        (ref.watch(memProvider(memId))?.toMap() ?? {})..[_memIdKey] = memId),
  ),
);

final memProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(null),
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
          final mem = await MemRepository().shipWhereIdIs(memId);
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

final saveMem = Provider.autoDispose.family<Future<bool>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final memId = memMap.remove(_memIdKey);

      Mem saved;
      if (Mem.isSavedMap(memMap)) {
        saved = await MemRepository().update(Mem.fromMap(memMap));
      } else {
        saved = await MemRepository().receive(memMap);
        ref
            .read(memProvider(saved.id).notifier)
            .updatedBy(Mem.fromMap(saved.toMap()));
      }

      ref
          .read(memProvider(memId).notifier)
          .updatedBy(Mem.fromMap(saved.toMap()));

      return true;
    },
  ),
);

final archiveMem = Provider.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final archived = await MemRepository().archive(Mem.fromMap(memMap));
      ref.read(memProvider(archived.id).notifier).updatedBy(archived);
      return archived;
    },
  ),
);

final unarchiveMem = Provider.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final unarchived = await MemRepository().unarchive(Mem.fromMap(memMap));
      ref.read(memProvider(unarchived.id).notifier).updatedBy(unarchived);
      return unarchived;
    },
  ),
);

final removeMem = Provider.family<Future<bool>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final result = await MemRepository().discardWhereIdIs(memId);
      ref.read(memProvider(memId).notifier).updatedBy(null);
      return result;
    },
  ),
);
