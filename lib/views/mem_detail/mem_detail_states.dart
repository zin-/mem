import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

final memMapProvider = StateNotifierProvider.autoDispose.family<
    ValueStateNotifier<Map<String, dynamic>>, Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier({}),
  ),
);

enum MemDetailPageState { newer, fetched, archived }

final memDetailPageStateProvider = StateNotifierProvider.family<
    ValueStateNotifier<MemDetailPageState>, MemDetailPageState, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(MemDetailPageState.newer),
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
          ref.read(memMapProvider(memId).notifier).updatedBy(mem.toMap());
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
      Mem saved;
      if (Mem.isSavedMap(memMap)) {
        saved = await MemRepository().update(Mem.fromMap(memMap));
      } else {
        saved = await MemRepository().receive(memMap);
        ref.read(memMapProvider(null).notifier).updatedBy(saved.toMap());
      }

      ref.read(memMapProvider(saved.id).notifier).updatedBy(saved.toMap());

      return true;
    },
  ),
);

final archiveMem = Provider.family<Future<Mem>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      final archived = await MemRepository().archive(Mem.fromMap(memMap));
      ref
          .read(memMapProvider(archived.id).notifier)
          .updatedBy(archived.toMap());
      ref
          .read(memDetailPageStateProvider(archived.id).notifier)
          .updatedBy(MemDetailPageState.archived);
      return archived;
    },
  ),
);
