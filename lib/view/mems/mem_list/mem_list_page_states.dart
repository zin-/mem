import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/services/mem_service.dart';
import 'package:mem/view/_atom/state_notifier.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_states.dart';

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
      memListNotifier.upsertAll(mems, (tmp, item) => tmp.id == item.id);
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

        // FIXME ここきもすぎない？
        final notifyOn1 = item1.notifyOn;
        final notifyOn2 = item2.notifyOn;
        if (notifyOn1 != notifyOn2) {
          if (notifyOn1 == null) {
            return 1;
          }
          if (notifyOn2 == null) {
            return -1;
          }
        }

        if (notifyOn1 != null && notifyOn2 != null) {
          final notifyAt1 = notifyOn1
              .subtract(Duration(
                hours: notifyOn1.hour,
                minutes: notifyOn1.minute,
                seconds: notifyOn1.second,
                milliseconds: notifyOn1.millisecond,
                microseconds: notifyOn1.microsecond,
              ))
              .add(Duration(
                hours: item1.notifyAt?.hour ?? 0,
                minutes: item1.notifyAt?.minute ?? 0,
              ));
          final notifyAt2 = notifyOn2
              .subtract(Duration(
                hours: notifyOn2.hour,
                minutes: notifyOn2.minute,
                seconds: notifyOn2.second,
                milliseconds: notifyOn2.millisecond,
                microseconds: notifyOn2.microsecond,
              ))
              .add(Duration(
                hours: item2.notifyAt?.hour ?? 0,
                minutes: item2.notifyAt?.minute ?? 0,
              ));

          final comparedNotifyAt = notifyAt1.compareTo(notifyAt2);

          if (comparedNotifyAt != 0) {
            return comparedNotifyAt;
          }
        }

        return item1.id!.compareTo(item2.id!);
      });

      return ValueStateNotifier(sortedMemList);
    },
  ),
);
