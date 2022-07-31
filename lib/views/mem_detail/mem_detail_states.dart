import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

final fetchMemById = FutureProvider.family<Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      var memMap = ref.read(memMapProvider(memId));

      if (memId != null && !Mem.isSaved(memMap)) {
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

final memMapProvider = StateNotifierProvider.family<
    ValueStateNotifier<Map<String, dynamic>>, Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier({}),
  ),
);

final saveMem = Provider.family<Future<bool>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'mem': memMap},
    () async {
      Mem saved = memMap.containsKey('id')
          ? await MemRepository().update(Mem.fromMap(memMap))
          : await MemRepository().receive(memMap);

      ref.read(memMapProvider(saved.id).notifier).updatedBy(saved.toMap());

      return true;
    },
  ),
);
