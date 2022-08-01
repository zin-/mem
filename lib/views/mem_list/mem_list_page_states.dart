import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/state_notifier.dart';

final fetchMemList = FutureProvider<List<Mem>>(
  (ref) => v(
    {},
    () async {
      final showArchived = ref.watch(showArchivedProvider);

      final mems = await MemRepository().ship(showArchived);

      ref.read(memListProvider.notifier).updatedBy(mems);
      mems.map((mem) =>
          ref.read(memMapProvider(mem.id).notifier).updatedBy(mem.toMap()));
      return mems;
    },
  ),
);

final memListProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>>(
  (ref) => v(
    {},
    () => ListValueStateNotifier<Mem>(
      [],
      filter: (item) {
        final showArchived = ref.watch(showArchivedProvider);
        if (showArchived != null) {
          if (showArchived) {
            return item.archivedAt != null;
          } else {
            return item.archivedAt == null;
          }
        } else {
          return true;
        }
      },
    ),
  ),
);

final showArchivedProvider = Provider<bool?>((ref) => false);
