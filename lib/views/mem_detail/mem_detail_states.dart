import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/mem.dart';
import 'package:mem/views/state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemState extends ValueStateNotifier<Map<String, dynamic>> {
  MemState(super.state);

  @override
  Map<String, dynamic> updatedBy(Map<String, dynamic> value) {
    final newValue = Map.of(value);
    return super.updatedBy(newValue);
  }
}

final memProvider =
    StateNotifierProvider.family<MemState, Map<String, dynamic>, int?>(
  (ref, memId) => MemState({}),
);

final fetchMemById = Provider.family<Future, int?>((ref, memId) async {
  try {
    if (memId != null) {
      final mem = await MemRepository().selectById(memId);
      ref.read(memProvider(memId).notifier).updatedBy(mem.toMap());
    }
  } catch (e) {
    print(e);
    ref.read(memProvider(memId).notifier).updatedBy({});
  }
});

final save =
    Provider.family<Future<bool>, Map<String, dynamic>>((ref, mem) async {
  if (mem.containsKey('id')) {
    final updated = await MemRepository().update(Mem.fromMap(mem));
    ref.read(memProvider(updated.id).notifier).updatedBy(updated.toMap());
  } else {
    final received = await MemRepository().receive(mem);
    ref.read(memProvider(received.id).notifier).updatedBy(received.toMap());
  }

  return true;
});
