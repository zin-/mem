import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/state_notifier.dart';

final fetchAllMem = FutureProvider<List<Mem>>(
  (ref) => v(
    {},
    () async {
      final mems = await MemRepository().shipAll();
      ref.read(memsProvider.notifier).updatedBy(mems);
      mems.map((mem) =>
          ref.read(memMapProvider(mem.id).notifier).updatedBy(mem.toMap()));
      return mems;
    },
  ),
);

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>>(
  (ref) => v(
    {},
    () => ListValueStateNotifier<Mem>([]),
  ),
);
