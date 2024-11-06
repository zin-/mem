import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/date_and_time/time_of_day.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/mem_notification_repository.dart';
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
    ListValueStateNotifier<SavedMemEntity>, List<SavedMemEntity>>(
  (ref) {
    final savedMems = ref.watch(memsProvider).whereType<SavedMemEntity>();

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
    ValueStateNotifier<List<SavedMemEntity>>, List<SavedMemEntity>>((ref) {
  final filtered = ref.watch(_filteredMemsProvider);
  final latestActsByMem = ref.watch(latestActsByMemProvider);
  final savedMemNotifications = ref.watch(savedMemNotificationsProvider);

  final now = DateTime.now();
  return ValueStateNotifier(
    v(
      () => filtered.sorted((a, b) {
        final latestActOfA =
            latestActsByMem.singleWhereOrNull((act) => act.memId == a.id);
        final latestActOfB =
            latestActsByMem.singleWhereOrNull((act) => act.memId == b.id);

        final comparedByActiveAct = Act.compare(
          latestActOfA,
          latestActOfB,
          onlyActive: true,
        );
        if (comparedByActiveAct != 0) {
          return comparedByActiveAct;
        }

        final memNotificationsOfA =
            savedMemNotifications.where((e) => e.memId == a.id);
        final memNotificationsOfB =
            savedMemNotifications.where((e) => e.memId == b.id);

        final startOfDay = ref.read(startOfDayProvider);
        final nowTime = TimeOfDay.fromDateTime(now);
        final startOfToday = DateTime(
          now.year,
          now.month,
          now.day + (startOfDay.lessThan(nowTime) ? 0 : 1),
          startOfDay.hour,
          startOfDay.minute,
        );

        final compared = a.compareTo(
          b,
          startOfToday,
          latestActOfThis: latestActOfA,
          latestActOfOther: latestActOfB,
          memNotificationsOfThis: memNotificationsOfA,
          memNotificationsOfOther: memNotificationsOfB,
        );
        if (compared != 0) {
          return compared;
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
              .sorted((a, b) => b.value.period.compareTo(a.value.period))
              .groupListsBy((e) => e.value.memId)
              .values
              .map((e) => e[0].value)
              .toList(),
        ),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            ref.read(actsProvider.notifier).addAll(
                  await ActRepository().ship(
                    memIdsIn: ref
                        .read(memsProvider)
                        .whereType<SavedMemEntity>()
                        .map((e) => e.id),
                    latestByMemIds: true,
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
    ListValueStateNotifier<SavedMemNotificationEntity>,
    List<SavedMemNotificationEntity>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(
        memNotificationsProvider.select(
            (value) => value.whereType<SavedMemNotificationEntity>().toList()),
      ),
      initializer: (current, notifier) => v(
        () async {
          if (current.isEmpty) {
            final memIds = ref
                .read(memsProvider)
                .whereType<SavedMemEntity>()
                .map((e) => e.id);

            final actsByMemIds = await MemNotificationRepository().ship(
              memIdsIn: memIds,
            );

            ref.read(memNotificationsProvider.notifier).upsertAll(
                  actsByMemIds,
                  (current, updating) =>
                      current is SavedMemNotificationEntity &&
                      updating is SavedMemNotificationEntity &&
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
    ListValueStateNotifier<SavedActEntity>, List<SavedActEntity>>(
  (ref) => v(
    () => ListValueStateNotifier(
      ref.watch(actsProvider).where((act) => act.value.isActive).toList(),
    ),
  ),
);

final searchTextProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<String?>, String?>(
  (ref) => ValueStateNotifier(null),
);
