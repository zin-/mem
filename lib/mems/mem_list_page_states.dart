import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_detail_states.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/gui/value_state_notifier.dart';

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
final showNotDoneProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    {},
    () => ValueStateNotifier(true),
  ),
);
final showDoneProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    {},
    () => ValueStateNotifier(false),
  ),
);

final fetchMemList = FutureProvider<void>(
  (ref) => v(
    {},
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final mems = (await MemService().fetchMems(
        showNotArchived,
        showArchived,
        showNotDone,
        showDone,
      ));

      ref
          .read(memListProvider.notifier)
          .upsertAll(mems, (tmp, item) => tmp.id == item.id);
      for (var mem in mems) {
        ref.read(memProvider(mem.id).notifier).updatedBy(mem);
      }
    },
  ),
);

final memListProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>?>(
  (ref) => v(
    {},
    () => ListValueStateNotifier<Mem>(null),
  ),
);
final reactiveMemListProvider =
    StateNotifierProvider<ValueStateNotifier<List<Mem>>, List<Mem>>(
  (ref) => v(
    {},
    () {
      final memList = ref.watch(memListProvider) ?? [];

      // FIXME Single Source of Truthに反している
      final reactiveMemList = memList
          .map((e) => ref.watch(memProvider(e.id)))
          .whereType<Mem>()
          .toList();

      return ValueStateNotifier(reactiveMemList);
    },
  ),
);
final filteredMemListProvider =
    StateNotifierProvider<ValueStateNotifier<List<Mem>>, List<Mem>>(
  (ref) => v(
    {},
    () {
      final reactiveMemList = ref.watch(reactiveMemListProvider);

      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final filteredMemList = reactiveMemList.where((item) {
        final archive = showNotArchived == showArchived
            ? true
            : item.archivedAt == null
                ? showNotArchived
                : showArchived;
        final done = showNotDone == showDone
            ? true
            : item.doneAt == null
                ? showNotDone
                : showDone;

        return archive && done;
      }).toList();

      return ValueStateNotifier(filteredMemList);
    },
  ),
);
final sortedMemList =
    StateNotifierProvider<ValueStateNotifier<List<Mem>>, List<Mem>>(
  (ref) => v(
    {},
    () {
      final filteredMemList = ref.watch(filteredMemListProvider);

      final sortedMemList = filteredMemList.sorted(
        (item1, item2) => v(
          {'item1': item1, 'item2': item2},
          () {
            if (item1.isDone() != item2.isDone()) {
              if (item1.isDone()) {
                return 1;
              }
              if (item2.isDone()) {
                return -1;
              }
            }

            if (item1.isArchived() != item2.isArchived()) {
              if (item1.isArchived()) {
                return 1;
              }
              if (item2.isArchived()) {
                return -1;
              }
            }

            final notifyAtV2_1 = item1.period?.start;
            final notifyAtV2_2 = item2.period?.start;
            if (notifyAtV2_1 != notifyAtV2_2) {
              if (notifyAtV2_1 == null) {
                return 1;
              }
              if (notifyAtV2_2 == null) {
                return -1;
              }

              final comparedNotifyAtV2 = notifyAtV2_1.compareTo(notifyAtV2_2);
              if (comparedNotifyAtV2 != 0) {
                return comparedNotifyAtV2;
              }
            }

            return item1.id!.compareTo(item2.id!);
          },
        ),
      );

      return ValueStateNotifier(sortedMemList);
    },
  ),
);
