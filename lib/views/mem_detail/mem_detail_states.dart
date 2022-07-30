import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

final fetchMemById = FutureProvider.family<Map<String, dynamic>, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      Mem? mem;
      if (memId == null) {
        mem = null;
      } else {
        try {
          mem = await MemRepository().selectById(memId);
        } catch (e) {
          print(e);
          mem = null;
        }
      }

      final memMap = mem?.toMap() ?? {};
      ref.watch(memMapProvider(memId).notifier).updatedBy(memMap);

      return memMap;
    },
  ),
);

final memMapProvider = StateNotifierProvider.family<
    ValueStateNotifier<Map<String, dynamic>>, Map<String, dynamic>, int?>(
  (ref, memId) => ValueStateNotifier({}),
);

final saveMem = Provider.family<Future<bool>, Map<String, dynamic>>(
  (ref, mem) => v(
    {'mem': mem},
    () async {
      Mem saved = mem.containsKey('id')
          ? await MemRepository().update(Mem.fromMap(mem))
          : await MemRepository().receive(mem);

      ref.read(memMapProvider(saved.id).notifier).updatedBy(saved.toMap());

      return true;
    },
  ),
);
