import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
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
        if (item1.doneAt != item2.doneAt) {
          if (item1.doneAt == null) {
            return -1;
          }
          if (item2.doneAt == null) {
            return 1;
          }
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

        final notifyOn1 = item1.notifyOn;
        final notifyOn2 = item2.notifyOn;
        if (notifyOn1 != notifyOn2) {
          if (notifyOn1 == null) {
            return 1;
          }
          if (notifyOn2 == null) {
            return -1;
          }
          return notifyOn1.compareTo(notifyOn2);
        }

        if (notifyOn1 != null && notifyOn2 != null) {
          final notifyAt1 = item1.notifyAt;
          final notifyAt2 = item2.notifyAt;

          if (notifyAt1 != notifyAt2) {
            if (notifyAt1 == null) {
              return -1;
            }
            if (notifyAt2 == null) {
              return 1;
            }

            return notifyOn1
                .add(Duration(
                  hours: notifyAt1.hour,
                  minutes: notifyAt1.minute,
                ))
                .compareTo(notifyOn2.add(Duration(
                  hours: notifyAt2.hour,
                  minutes: notifyAt2.minute,
                )));
          }
        }

        return item1.id!.compareTo(item2.id!);
      });

      return ValueStateNotifier(sortedMemList);
    },
  ),
);

extension TimeOfDayExtension on TimeOfDay {
  int compareTo(TimeOfDay other) {
    if (hour != other.hour) {
      return hour.compareTo(other.hour);
    }
    if (minute != other.minute) {
      return minute.compareTo(other.minute);
    }
    return 0;
  }
}
