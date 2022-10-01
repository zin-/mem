import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/services/mem_service.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';

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

      final memListNotifier = ref.read(memListProvider.notifier);
      for (var mem in mems) {
        ref.read(memProvider(mem.id).notifier).updatedBy(mem);
        memListNotifier.upsert(mem, (item) => item.id == mem.id);
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

      final sortedMemList = filteredMemList.sorted((item1, item2) {
        if (item1.doneAt != item2.doneAt) {
          if (item1.doneAt == null) {
            return -1;
          }
          if (item2.doneAt == null) {
            return 1;
          }
          return item1.doneAt!.compareTo(item2.doneAt!);
        }

        if (item1.archivedAt != item2.archivedAt) {
          if (item1.archivedAt == null) {
            return -1;
          }
          if (item2.archivedAt == null) {
            return 1;
          }
          return item1.archivedAt!.compareTo(item2.archivedAt!);
        }

        if (item1.id == null) {
          return -1;
        }
        if (item2.id == null) {
          return 1;
        }
        return item1.id!.compareTo(item2.id!);
      });

      return ValueStateNotifier(sortedMemList);
    },
  ),
);
