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
      for (var mem in mems) {
        ref.read(memProvider(mem.id).notifier).updatedBy(mem);
      }

      return mems;
    },
  ),
);

final memListProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>>(
  (ref) => v(
    {},
    // TODO ListValueStateは要素が変更されたらリスナーに通知して欲しい
    // これは、Viewがそれぞれに要素を見るという話ではなく、ListValueStateが持っていて欲しい
    () {
      final listValueState = ListValueStateNotifier<Mem>(
        [],
        // FIXME filterはstateが持つものじゃない気がする
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
      );

      return listValueState;
    },
  ),
);

final showArchivedProvider = Provider<bool?>((ref) => v({}, () => false));
