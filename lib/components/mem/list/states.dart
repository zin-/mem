import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/app_bar/states.dart';
import 'package:mem/mems/states.dart';

final showNotArchivedProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    () => ValueStateNotifier(true),
  ),
);
final showArchivedProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    () => ValueStateNotifier(false),
  ),
);
final showNotDoneProvider =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    () => ValueStateNotifier(true),
  ),
);
final showDoneProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => v(
    () => ValueStateNotifier(false),
  ),
);

final memListProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<List<Mem>>, List<Mem>>(
        (ref) {
  final rawMemList = ref.watch(memsProvider) ?? <MemV2>[];

  final showNotArchived = ref.watch(showNotArchivedProvider);
  final showArchived = ref.watch(showArchivedProvider);
  final showNotDone = ref.watch(showNotDoneProvider);
  final showDone = ref.watch(showDoneProvider);
  final searchText = ref.watch(searchTextProvider);
  final filtered = v(
    () => rawMemList.where((mem) {
      if (searchText == null || searchText.isEmpty) {
        return true;
      } else {
        return mem.name.contains(searchText);
      }
    }).where((mem) {
      if (showNotArchived == showArchived) {
        return true;
      } else {
        return showArchived
            ? mem is SavedMemV2 && mem.isArchived
            : !(mem is SavedMemV2 ? mem.isArchived : false);
      }
    }).where((mem) {
      if (showNotDone == showDone) {
        return true;
      } else {
        return showDone ? mem.isDone : !mem.isDone;
      }
    }).toList(),
    {
      rawMemList,
      showNotArchived,
      showArchived,
      showNotDone,
      showDone,
      searchText,
    },
  );

  final activeActs = ref.watch(activeActsProvider);
  final sorted = v(
    () => filtered.sorted((a, b) {
      final activeActOfA = activeActs
          ?.singleWhereOrNull((act) => a is SavedMemV2 && act.memId == a.id);
      final activeActOfB = activeActs
          ?.singleWhereOrNull((act) => b is SavedMemV2 && act.memId == b.id);
      if ((activeActOfA == null) ^ (activeActOfB == null)) {
        return activeActOfA == null ? 1 : -1;
      } else if (activeActOfA != null && activeActOfB != null) {
        final c =
            activeActOfA.period.start!.compareTo(activeActOfB.period.start!);
        if (c != 0) {
          return c;
        }
      }

      if ((a is SavedMemV2 && a.isArchived) !=
          (b is SavedMemV2 && b.isArchived)) {
        return a is SavedMemV2 && a.isArchived ? 1 : -1;
      }
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }

      final comparedPeriod = DateAndTimePeriod.compare(a.period, b.period);
      if (comparedPeriod != 0) {
        return comparedPeriod;
      }

      return a is SavedMemV2 && b is SavedMemV2
          ? (a.id as int).compareTo(b.id)
          : 0;
    }).toList(),
    {filtered, activeActs},
  );

  return ValueStateNotifier(sorted.map((e) => e.toV1()).toList());
});

final activeActsProvider =
    StateNotifierProvider.autoDispose<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(() => ListValueStateNotifier<Act>(
        ref
            .watch(actsProvider)
            ?.where((act) => act.period.end == null)
            .toList(),
      )),
);
