import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:mem/settings/states.dart';
import 'package:mem/values/constants.dart';

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
    ListValueStateNotifier<SavedMemEntityV2>, List<SavedMemEntityV2>>(
  (ref) {
    final savedMems = ref.watch(memsProvider).whereType<SavedMemEntityV2>();

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
            return showDone ? mem.value.isDone : !mem.value.isDone;
          }
        }).where((mem) {
          // FIXME searchTextがある場合、Memの状態に関わらずsearchTextだけでフィルターした方が良いかも
          if (searchText == null || searchText.isEmpty) {
            return true;
          } else {
            return mem.value.name.contains(searchText);
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
    ValueStateNotifier<List<SavedMemEntityV2>>, List<SavedMemEntityV2>>((ref) {
  final filtered = ref.watch(_filteredMemsProvider);
  final latestActsByMem = ref.watch(latestActsByMemProvider);
  final savedMemNotifications = ref.watch(savedMemNotificationsProvider);

  final startOfToday = DateTimeExt.startOfToday(
    ref.watch(preferencesProvider).value?[startOfDayKey] ?? defaultStartOfDay,
  );

  return ValueStateNotifier(
    v(
      () => filtered.sorted((a, b) {
        final latestActOfA =
            latestActsByMem.singleWhereOrNull((act) => act.memId == a.id);
        final latestActOfB =
            latestActsByMem.singleWhereOrNull((act) => act.memId == b.id);

        final comparedActState = (latestActOfA?.state ?? ActState.finished)
            .index
            .compareTo((latestActOfB?.state ?? ActState.finished).index);
        if (comparedActState != 0) {
          return comparedActState;
        } else if (latestActOfA is ActiveAct && latestActOfB is ActiveAct) {
          return latestActOfB.period!.start!
              .compareTo(latestActOfA.period!.start!);
        }

        if (a.isArchived != b.isArchived) {
          return a.isArchived ? 1 : -1;
        }
        if (a.value.isDone != b.value.isDone) {
          return a.value.isDone ? 1 : -1;
        }

        final memNotificationsOfA =
            savedMemNotifications.where((e) => e.value.memId == a.id);
        final memNotificationsOfB =
            savedMemNotifications.where((e) => e.value.memId == b.id);

        final timeOfThis = a.value.notifyAt(
          startOfToday,
          memNotificationsOfA.map((e) => e.value),
          latestActOfA,
        );
        final timeOfOther = b.value.notifyAt(
          startOfToday,
          memNotificationsOfB.map((e) => e.value),
          latestActOfB,
        );

        if (timeOfThis != null || timeOfOther != null) {
          if (timeOfThis == null) {
            return 1;
          } else if (timeOfOther == null) {
            return -1;
          } else {
            return timeOfThis.compareTo(timeOfOther);
          }
        }

        final thisHasAfterActStarted = memNotificationsOfA
            .where((e) => e.value.isAfterActStarted())
            .isNotEmpty;
        final otherHasAfterActStarted = memNotificationsOfB
            .where((e) => e.value.isAfterActStarted())
            .isNotEmpty;
        if (thisHasAfterActStarted != otherHasAfterActStarted) {
          return thisHasAfterActStarted ? -1 : 1;
        }

        return a.id.compareTo(b.id);
      }).toList(),
      {
        'filtered': filtered,
        'latestActsByMem': latestActsByMem,
        'savedMemNotifications': savedMemNotifications,
      },
    ),
  );
});

final latestActsByMemProvider =
    StateNotifierProvider.autoDispose<ListValueStateNotifier<Act>, List<Act>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(
        actsProvider.select(
          (value) => value
              .groupListsBy((e) => e.value.memId)
              .values
              .map((e) => e
                  .sorted(
                    (a, b) => (b.value.period?.start ?? b.createdAt)
                        .compareTo(a.value.period?.start ?? a.createdAt),
                  )[0]
                  .value)
              .toList(),
        ),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            ref.read(actsProvider.notifier).addAll(
                  await ActService().fetchLatestByMemIds(
                    ref
                        .read(memsProvider)
                        .whereType<SavedMemEntityV2>()
                        .map((e) => e.id),
                  ),
                );
          }
        },
        {'current': current},
      ),
    ),
  ),
);
final savedMemNotificationsProvider = StateNotifierProvider.autoDispose<
    ListValueStateNotifier<SavedMemNotificationEntityV2>,
    List<SavedMemNotificationEntityV2>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(
        memNotificationsProvider.select(
          (v) => v.whereType<SavedMemNotificationEntityV2>().toList(),
        ),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            ref.read(memNotificationsProvider.notifier).upsertAll(
                  await MemNotificationRepositoryV2().ship(
                    memIdsIn: ref
                        .read(memsProvider)
                        .whereType<SavedMemEntityV2>()
                        .map((e) => e.id),
                  ),
                  (current, updating) =>
                      current is SavedMemNotificationEntityV2 &&
                      updating is SavedMemNotificationEntityV2 &&
                      current.id == updating.id,
                );
          }
        },
        {'current': current},
      ),
    ),
  ),
);

final searchTextProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<String?>, String?>(
  (ref) => ValueStateNotifier(null),
);
