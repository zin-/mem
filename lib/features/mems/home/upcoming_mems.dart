import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/home/home_mems.dart';
import 'package:mem/features/mems/home/mems_by_notify_at.dart';
import 'package:mem/features/mems/mem_entity.dart';

const _upcomingMemsCount = 3;

final upcomingMemsProvider = Provider.autoDispose<List<MemEntity>>(
  (ref) => HomeMems.of(ref, upcomingMems),
);

List<MemEntity> upcomingMems(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime now,
  required DateTime startOfToday,
  Map<int, int> periodCountByMemId = const {},
}) =>
    MemsByNotifyAt.of(
      mems,
      savedMemNotifications,
      startOfToday: startOfToday,
      periodCountByMemId: periodCountByMemId,
      include: (notifyAt) => !notifyAt.isBefore(now),
    ).mems.take(_upcomingMemsCount).toList();
