import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/settings/states.dart';

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
  final latestActsByMem = ref.watch(latestActsByMemProvider);
  final savedMemNotifications = ref.watch(savedMemNotificationsProvider);

  return ValueStateNotifier(
    v(
      () => filtered.sorted((a, b) {
        final latestActOfA =
            latestActsByMem.singleWhereOrNull((act) => act.memId == a.id);
        final latestActOfB =
            latestActsByMem.singleWhereOrNull((act) => act.memId == b.id);
        final comparedByActiveAct =
            Act.activeCompare(latestActOfA, latestActOfB);
        if (comparedByActiveAct != 0) {
          return comparedByActiveAct;
        }

        if ((a.isArchived) != (b.isArchived)) {
          return a.isArchived ? 1 : -1;
        }
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }

        final memNotificationsOfA =
            savedMemNotifications.where((e) => e.memId == a.id);
        final memNotificationsOfB =
            savedMemNotifications.where((e) => e.memId == b.id);

        final startOfDay = ref.read(startOfDayProvider);
        final now = DateTime.now();
        final comparedTime = _compareTime(
          a.period,
          MemNotifications.nextRepeatNotifyAt(
            memNotificationsOfA,
            startOfDay,
            latestActOfA,
            now,
          ),
          b.period,
          MemNotifications.nextRepeatNotifyAt(
            memNotificationsOfB,
            startOfDay,
            latestActOfB,
            now,
          ),
        );
        if (comparedTime != 0) {
          return comparedTime;
        }

        return a.id.compareTo(b.id);
      }).toList(),
      {
        'filtered': filtered,
        'latestActsByMem': latestActsByMem,
      },
    ),
  );
});

int _compareTime(
  DateAndTimePeriod? periodOfA,
  DateTime? nextNotifyAtOfA,
  DateAndTimePeriod? periodOfB,
  DateTime? nextNotifyAtOfB,
) =>
    v(
      () {
        if ((periodOfA == null && nextNotifyAtOfA == null) &&
            (periodOfB == null && nextNotifyAtOfB == null)) {
          return 0;
        } else if (nextNotifyAtOfA != null && nextNotifyAtOfB != null) {
          return nextNotifyAtOfA.compareTo(nextNotifyAtOfB);
        } else if (periodOfA != null && nextNotifyAtOfB != null) {
          return periodOfA.compareWithDateAndTime(nextNotifyAtOfB);
        } else if (nextNotifyAtOfA != null && periodOfB != null) {
          return -periodOfB.compareWithDateAndTime(nextNotifyAtOfA);
        } else if ((periodOfA == null && nextNotifyAtOfA == null) ||
            (periodOfB == null && nextNotifyAtOfB == null)) {
          return (periodOfA == null && nextNotifyAtOfA == null) ? 1 : -1;
        } else {
          return DateAndTimePeriod.compare(periodOfA, periodOfB);
        }
      },
      {
        'periodOfA': periodOfA,
        'nextNotifyAtOfA': nextNotifyAtOfA,
        'periodOfB': periodOfB,
        'nextNotifyAtOfB': nextNotifyAtOfB,
      },
    );

final latestActsByMemProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedAct>, List<SavedAct>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(
        actsProvider.select(
          (value) => value
              .sorted((a, b) => b.period.compareTo(a.period))
              .groupListsBy((element) => element.memId)
              .values
              .map((e) => e[0])
              .toList(),
        ),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            final memIds =
                ref.read(memsProvider).whereType<SavedMem>().map((e) => e.id);

            final actsByMemIds = await ActRepository().ship(
              memIdsIn: memIds,
              latestByMemIds: true,
            );

            ref.read(actsProvider.notifier).addAll(actsByMemIds);
          }
        },
        {'current': current},
      ),
    ),
  ),
);
final savedMemNotificationsProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedMemNotification>, List<SavedMemNotification>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(
        memNotificationsProvider.select(
            (value) => value.whereType<SavedMemNotification>().toList()),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            final memIds =
                ref.read(memsProvider).whereType<SavedMem>().map((e) => e.id);

            final actsByMemIds = await MemNotificationRepository().ship(
              memIdsIn: memIds,
            );

            ref.read(memNotificationsProvider.notifier).upsertAll(
                  actsByMemIds,
                  (current, updating) =>
                      current is SavedMemNotification &&
                      updating is SavedMemNotification &&
                      current.id == updating.id,
                );
          }
        },
        {'current': current},
      ),
    ),
  ),
);

final activeActsProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedAct>, List<SavedAct>>(
  (ref) => v(() => ListValueStateNotifier(
        ref.watch(actsProvider).where((act) => act.period.end == null).toList(),
      )),
);
