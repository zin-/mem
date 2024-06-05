import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

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
final _filteredMemsProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedMem>, List<SavedMem>>(
  (ref) {
    final savedMems = ref.watch(memsProvider).map((e) => e as SavedMem);

    final showNotArchived = ref.watch(showNotArchivedProvider);
    final showArchived = ref.watch(showArchivedProvider);
    final showNotDone = ref.watch(showNotDoneProvider);
    final showDone = ref.watch(showDoneProvider);
    final searchText = ref.watch(searchTextProvider);

    return ListValueStateNotifier(
      v(
        () => savedMems.where((mem) {
          if (showNotArchived == showArchived) {
            return true;
          } else {
            return showArchived ? mem.isArchived : !mem.isArchived;
          }
        }).where((mem) {
          if (showNotDone == showDone) {
            return true;
          } else {
            return showDone ? mem.isDone : !mem.isDone;
          }
        }).where((mem) {
          // FIXME searchTextがある場合、Memの状態に関わらずsearchTextだけでフィルターした方が良いかも
          if (searchText == null || searchText.isEmpty) {
            return true;
          } else {
            return mem.name.contains(searchText);
          }
        }).toList(),
        {
          'savedMems': savedMems,
          'showNotArchived': showNotArchived,
          'showArchived': showArchived,
          'showNotDone': showNotDone,
          'showDone': showDone,
          'searchText': searchText,
        },
      ),
    );
  },
);

final memListProvider = StateNotifierProvider.autoDispose<
    ValueStateNotifier<List<SavedMem>>, List<SavedMem>>((ref) {
  final filtered = ref.watch(_filteredMemsProvider);

  final activeActs = ref.watch(activeActsProvider);
  final sorted = v(
    () => filtered.sorted((a, b) {
      final comparedByActiveAct = _compareActiveAct(
        activeActs.singleWhereOrNull((act) => act.memId == a.id),
        activeActs.singleWhereOrNull((act) => act.memId == b.id),
      );
      if (comparedByActiveAct != 0) {
        return comparedByActiveAct;
      }

      if ((a.isArchived) != (b.isArchived)) {
        return a.isArchived ? 1 : -1;
      }
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }

      final comparedPeriod = DateAndTimePeriod.compare(a.period, b.period);
      if (comparedPeriod != 0) {
        return comparedPeriod;
      }

      return a.id.compareTo(b.id);
    }).toList(),
    {filtered, activeActs},
  );

  return ValueStateNotifier(sorted);
});

int _compareActiveAct(Act? activeActOfA, Act? activeActOfB) => v(
      () {
        if (activeActOfA == null && activeActOfB == null) {
          return 0;
        } else if (activeActOfA != null && activeActOfB != null) {
          return activeActOfA.period.start!
              .compareTo(activeActOfB.period.start!);
        } else {
          return activeActOfA == null ? 1 : -1;
        }
      },
      {'activeActOfA': activeActOfA, 'activeActOfB': activeActOfB},
    );

final activeActsProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedAct>, List<SavedAct>>(
  (ref) => v(() => ListValueStateNotifier(
        ref.watch(actsProvider).where((act) => act.period.end == null).toList(),
      )),
);
