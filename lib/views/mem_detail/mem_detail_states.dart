import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/mem_list/mem_list_page_states.dart';
import 'package:mem/views/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

final fetchMemById =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int?>(
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

final saveMem = Provider.autoDispose.family<Future<bool>, Map<String, dynamic>>(
  (ref, memMap) => v(
    {'memMap': memMap},
    () async {
      Mem saved;

      final memsNotifier = ref.read(memsProvider.notifier);
      if (Mem.isSaved(memMap)) {
        saved = await MemRepository().update(Mem.fromMap(memMap));
        memsNotifier.updateWhere(saved, (mem) => mem.id == saved.id);
      } else {
        saved = await MemRepository().receive(memMap);
        memsNotifier.add(saved);
        ref.read(memMapProvider(null).notifier).updatedBy(saved.toMap());
      }

      ref.read(memMapProvider(saved.id).notifier).updatedBy(saved.toMap());

      return true;
    },
  ),
);
