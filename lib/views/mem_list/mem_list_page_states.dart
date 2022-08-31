import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/atoms/state_notifier.dart';

final fetchMemList = FutureProvider<List<Mem>>(
  (ref) => v(
    {},
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);

      final archived = showNotArchived == showArchived ? null : showArchived;
      final mems = await MemRepository().ship(archived);

      for (var mem in mems) {
        ref.read(memListProvider.notifier).add(
              mem,
              (item) => item.id == mem.id,
            );
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
        filter: (item) {
          final showNotArchived = ref.watch(showNotArchivedProvider);
          final showArchived = ref.watch(showArchivedProvider);

          if (showNotArchived == showArchived) {
            return true;
          } else {}
          if (item.archivedAt == null) {
            return ref.watch(showNotArchivedProvider);
          } else {
            return ref.watch(showArchivedProvider);
          }
        },
        compare: (item1, item2) {
          if (item1.archivedAt != item2.archivedAt) {
            if (item1.archivedAt == null) {
              return -1;
            }
            if (item2.archivedAt == null) {
              return 1;
            }
            return item1.archivedAt!.compareTo(item2.archivedAt!);
          }

          return item1.id.compareTo(item2.id);
        },
      );

      return listValueState;
    },
  ),
);

final showNotArchivedProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    {},
    () => ValueStateNotifier(true),
  ),
);
final showArchivedProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    {},
    () => ValueStateNotifier(false),
  ),
);
