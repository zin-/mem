import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

final upcomingMemsProvider = Provider.autoDispose<List<MemEntity>>((ref) {
  ref.listen(loadMemListProvider, (_, __) {});

  final mems = ref.watch(memEntitiesProvider);
  final savedMemNotifications = ref.watch(savedMemNotificationsProvider);
  final periodCountByMemId =
      ref.watch(listPeriodCountByMemIdProvider).value ?? const {};
  final startOfToday = DateTimeExt.startOfToday(
    ref.watch(preferenceProvider(startOfDayKey)),
  );

  return v(
    () => upcomingMems(
      mems,
      savedMemNotifications,
      now: DateTime.now(),
      startOfToday: startOfToday,
      periodCountByMemId: periodCountByMemId,
    ),
    {
      'mems': mems,
      'savedMemNotifications': savedMemNotifications,
      'startOfToday': startOfToday,
      'periodCountByMemId': periodCountByMemId,
    },
  );
});

List<MemEntity> upcomingMems(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime now,
  required DateTime startOfToday,
  Map<int, int> periodCountByMemId = const {},
}) =>
    _memsByNotifyAt(
      mems,
      savedMemNotifications,
      startOfToday: startOfToday,
      periodCountByMemId: periodCountByMemId,
      include: (notifyAt) => !notifyAt.isBefore(now),
    ).take(3).toList();

List<MemEntity> overdueMems(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime now,
  required DateTime startOfToday,
  Map<int, int> periodCountByMemId = const {},
}) =>
    _memsByNotifyAt(
      mems,
      savedMemNotifications,
      startOfToday: startOfToday,
      periodCountByMemId: periodCountByMemId,
      include: (notifyAt) => notifyAt.isBefore(now),
    );

List<MemEntity> _memsByNotifyAt(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime startOfToday,
  required Map<int, int> periodCountByMemId,
  required bool Function(DateTime notifyAt) include,
}) {
  final selected = <({MemEntity mem, DateTime notifyAt})>[];
  for (final mem in mems) {
    if (mem.isArchived || mem.doneAt != null) {
      continue;
    }
    final notifyAt = _notifyAtOf(
      mem,
      savedMemNotifications,
      startOfToday,
      periodCountByMemId,
    );
    if (notifyAt == null || !include(notifyAt)) {
      continue;
    }
    selected.add((mem: mem, notifyAt: notifyAt));
  }

  selected.sort((a, b) {
    final compared = a.notifyAt.compareTo(b.notifyAt);
    if (compared != 0) {
      return compared;
    }
    return a.mem.id.compareTo(b.mem.id);
  });

  return selected.map((entry) => entry.mem).toList();
}

DateTime? _notifyAtOf(
  MemEntity mem,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications,
  DateTime startOfToday,
  Map<int, int> periodCountByMemId,
) =>
    mem
        .toDomain()
        .notifyAt(
          startOfToday,
          savedMemNotifications
              .where((notification) => notification.value.memId == mem.id)
              .map((notification) => notification.value),
          mem.latestAct,
          target: mem.target,
          todayCount: periodCountByMemId[mem.id] ?? 0,
        )
        ?.at;
