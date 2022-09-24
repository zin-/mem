import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';
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

final fetchMemList = FutureProvider<List<MemEntity>>(
  (ref) => v(
    {},
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      // final showNotDone = ref.watch(showNotDoneProvider);
      // final showDone = ref.watch(showDoneProvider);

      final mems = await MemRepository().ship(
        whereMap: buildNullableWhere(
          archivedAtColumnName,
          showNotArchived == showArchived ? null : showArchived,
        ),
      );

      final memListNotifier = ref.read(memListProvider.notifier);
      for (var mem in mems) {
        ref.read(memProvider(mem.id).notifier).updatedBy(mem);
        memListNotifier.upsert(mem, (item) => item.id == mem.id);
      }

      return mems;
    },
  ),
);

final memListProvider =
    StateNotifierProvider<ListValueStateNotifier<MemEntity>, List<MemEntity>?>(
  (ref) => v(
    {},
    () => ListValueStateNotifier<MemEntity>(null),
  ),
);
final reactiveMemListProvider =
    StateNotifierProvider<ValueStateNotifier<List<MemEntity>>, List<MemEntity>>(
  (ref) => v(
    {},
    () {
      final memList = ref.watch(memListProvider) ?? [];

      final reactiveMemList = memList
          .map((e) => ref.watch(memProvider(e.id)))
          .whereType<MemEntity>()
          .toList();

      return ValueStateNotifier(reactiveMemList);
    },
  ),
);
final filteredMemListProvider =
    StateNotifierProvider<ValueStateNotifier<List<MemEntity>>, List<MemEntity>>(
  (ref) => v(
    {},
    () {
      final memList = ref.watch(reactiveMemListProvider);

      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      // final showNotDone = ref.watch(showNotDoneProvider);
      // final showDone = ref.watch(showDoneProvider);

      final filteredMemList = memList.where((item) {
        if (showNotArchived == showArchived) {
          return true;
        }
        if (item.archivedAt == null) {
          return showNotArchived;
        } else {
          return showArchived;
        }
        // if (showNotDone == showDone) {
        //   return true;
        // }
        // if (item.doneAt == null) {
        //   return showNotDone;
        // } else {
        //   return showDone;
        // }
      }).toList();

      return ValueStateNotifier(filteredMemList);
    },
  ),
);
final sortedMemList =
    StateNotifierProvider<ValueStateNotifier<List<MemEntity>>, List<MemEntity>>(
  (ref) => v(
    {},
    () {
      final filteredMemList = ref.watch(filteredMemListProvider);

      final sortedMemList = filteredMemList.sorted((item1, item2) {
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
      });

      return ValueStateNotifier(sortedMemList);
    },
  ),
);
