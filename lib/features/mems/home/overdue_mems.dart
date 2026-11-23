import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/home/home_mems.dart';
import 'package:mem/features/mems/home/mems_by_notify_at.dart';
import 'package:mem/features/mems/mem_entity.dart';

final overdueMemsProvider =
    FutureProvider.autoDispose<List<MemEntity>>((ref) async {
  return HomeMems.of(
    ref,
    (mems, savedMemNotifications, {
      required DateTime now,
      required DateTime startOfToday,
      Map<int, int> periodCountByMemId = const {},
    }) =>
        MemsByNotifyAt.of(
          mems,
          savedMemNotifications,
          startOfToday: startOfToday,
          periodCountByMemId: periodCountByMemId,
          include: (notifyAt) => notifyAt.isBefore(now),
        ).mems,
  );
});
