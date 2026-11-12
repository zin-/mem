import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemsByNotifyAt {
  final List<MemEntity> mems;

  MemsByNotifyAt._(this.mems);

  static MemsByNotifyAt of(
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

    return MemsByNotifyAt._(selected.map((entry) => entry.mem).toList());
  }

  static DateTime? _notifyAtOf(
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
}
