import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/home/mems_by_notify_at.dart';
import 'package:mem/features/mems/list/list_period_count.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'overdue_mems.g.dart';

@Riverpod()
class OverdueMems extends _$OverdueMems {
  bool _loaded = false;

  @override
  List<MemEntity> build() => v(() => const []);

  Future<List<MemEntity>> load() => d(() async {
        if (_loaded) return state;

        final now = DateTime.now();
        final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
        final startOfToday = DateTimeExt.startOfToday(startOfDay, now);

        final repository = MemRepository();
        final candidateIds = await repository.shipOverdueCandidateIds(now: now);
        if (candidateIds.isEmpty) return const [];

        final mems = await repository.shipOverdueMaterials(candidateIds);

        // 間隔目標だけ回数を読んでから選ぶ。未取得を 0 扱いにしない
        final periodCountByMemId =
            await ActQueryService().listPeriodCountsByMemId(
          mems: [
            for (final mem in mems)
              if (mem.target?.secondsAfterLastAct != null)
                (
                  id: mem.id,
                  target: mem.target,
                  period: ListPeriodCount.period(
                    target: mem.target!,
                    latestAct: mem.latestAct,
                    scheduleAnchorAct: mem.scheduleAnchorAct,
                    startOfDay: startOfDay,
                    now: now,
                  ),
                ),
          ],
        );

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
          periodCountByMemId: periodCountByMemId,
          include: (notifyAt) => notifyAt.isBefore(now),
        );

        _loaded = true;
        state = memsByNotifyAt.mems;

        return memsByNotifyAt.mems;
      });
}
