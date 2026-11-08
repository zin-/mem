import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';

List<MemEntity> upcomingMems(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime now,
  required DateTime startOfToday,
}) {
  DateTime? notifyAtOf(MemEntity mem) => mem.toDomain().notifyAt(
        startOfToday,
        savedMemNotifications
            .where((notification) => notification.value.memId == mem.id)
            .map((notification) => notification.value),
        mem.latestAct,
      );

  final upcoming = <({MemEntity mem, DateTime notifyAt})>[];
  for (final mem in mems) {
    if (mem.isArchived || mem.doneAt != null) {
      continue;
    }
    final notifyAt = notifyAtOf(mem);
    if (notifyAt == null || notifyAt.isBefore(now)) {
      continue;
    }
    upcoming.add((mem: mem, notifyAt: notifyAt));
  }

  upcoming.sort((a, b) {
    final compared = a.notifyAt.compareTo(b.notifyAt);
    if (compared != 0) {
      return compared;
    }
    return a.mem.id.compareTo(b.mem.id);
  });

  return upcoming.take(3).map((entry) => entry.mem).toList();
}
