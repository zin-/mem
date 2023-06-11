import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service_v2.dart';

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

final rawMemListProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>?>(
  (ref) => v(
    () {
      return ListValueStateNotifier<Mem>(null);
    },
  ),
);

final memListProvider =
    StateNotifierProvider<ValueStateNotifier<List<Mem>>, List<Mem>>(
  (ref) => v(
    () {
      final rawMemList = ref.watch(rawMemListProvider) ?? <Mem>[];

      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final filtered = rawMemList.where((mem) {
        if (showNotArchived == showArchived) {
          return true;
        } else {
          return showArchived ? mem.isArchived() : !mem.isArchived();
        }
      }).where((mem) {
        if (showNotDone == showDone) {
          return true;
        } else {
          return showDone ? mem.isDone() : !mem.isDone();
        }
      }).toList();

      final activeActs = ref.watch(activeActsProvider);

      final sorted = filtered.sorted((a, b) {
        final activeActOfA =
            activeActs?.singleWhereOrNull((act) => act.memId == a.id);
        final activeActOfB =
            activeActs?.singleWhereOrNull((act) => act.memId == b.id);
        if ((activeActOfA == null) ^ (activeActOfB == null)) {
          return activeActOfA == null ? 1 : -1;
        } else if (activeActOfA != null && activeActOfB != null) {
          final c =
              activeActOfA.period.start!.compareTo(activeActOfB.period.start!);
          if (c != 0) {
            return c;
          }
        }

        if (a.isArchived() != b.isArchived()) {
          return a.isArchived() ? 1 : -1;
        }
        if (a.isDone() != b.isDone()) {
          return a.isDone() ? 1 : -1;
        }

        final aPeriod = a.period;
        final bPeriod = b.period;
        if (aPeriod != null && bPeriod != null) {
          return aPeriod.compareTo(bPeriod);
        } else if (aPeriod != null || bPeriod != null) {
          return aPeriod == null ? 1 : -1;
        }

        return (a.id as int).compareTo(b.id);
      }).toList();

      return ValueStateNotifier(sorted);
    },
  ),
);

final activeActsProvider =
    StateNotifierProvider<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(() {
    return ListValueStateNotifier<Act>(null);
  }),
);
