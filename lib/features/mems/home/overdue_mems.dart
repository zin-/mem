import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/home/mems_by_notify_at.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'overdue_mems.g.dart';

@Riverpod()
class OverdueMems extends _$OverdueMems {
  bool _loaded = false;

  @override
  List<MemEntity> build() => v(() {
        final now = DateTime.now();
        final startOfDay = ref.read(preferenceProvider(startOfDayKey));
        final startOfToday = DateTimeExt.startOfToday(startOfDay, now);

        final mems = ref.watch(memEntitiesProvider);

        final notifications = [
          for (final mem in mems)
            for (final notification
                in mem.repeatedNotifications ?? const <MemNotificationEntity>[])
              SavedMemNotificationEntityV1.fromEntityV2(notification),
        ];

        final periodCountByMemId = ref
            .read(actCountsByMemIdByDateProvider(now))
            .map((memId, count) => MapEntry(memId, count));

        final memsByNotifyAt = MemsByNotifyAt.of(
          mems,
          notifications,
          startOfToday: startOfToday,
          periodCountByMemId: periodCountByMemId,
          include: (notifyAt) => notifyAt.isBefore(now),
        );

        return memsByNotifyAt.mems;
      });

  Future<List<MemEntity>> load() => v(() async {
        if (_loaded) return state;

        final now = DateTime.now();
        final startOfDay = ref.read(preferenceProvider(startOfDayKey));
        final startOfToday = now.atStartOfDay(startOfDay);

        final repository = MemRepository();
        final candidateIds = await repository.shipOverdueCandidateIds(now: now);
        if (candidateIds.isEmpty) return const [];

        final mems = await repository.shipOverdueMaterials(candidateIds);

        // 間隔目標だけ回数を読んでから選ぶ。未取得を 0 扱いにしない
        final actCountsByMemId = await ref
            .read(actCountsByMemIdByDateProvider(now).notifier)
            .load(now);

        final notifications = [
          for (final mem in mems)
            for (final notification
                in mem.repeatedNotifications ?? const <MemNotificationEntity>[])
              SavedMemNotificationEntityV1.fromEntityV2(notification),
        ];

        final memsByNotifyAt = MemsByNotifyAt.of(
          mems,
          notifications,
          startOfToday: startOfToday,
          periodCountByMemId: actCountsByMemId,
          include: (notifyAt) => notifyAt.isBefore(now),
        );

        _loaded = true;
        state = memsByNotifyAt.mems;

        return memsByNotifyAt.mems;
      });
}
