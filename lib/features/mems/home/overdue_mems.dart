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
  final _memRepository = MemRepository();

  bool _loaded = false;

  @override
  List<MemEntity> build() => v(() {
        final now = DateTime.now();
        final startOfToday =
            now.atStartOfDay(ref.read(preferenceProvider(startOfDayKey)));
        final mems = ref.watch(memEntitiesProvider);
        final counted = ref.watch(actCountsByMemIdByDateProvider(now));

        return _overdueMems(
          mems,
          _loaded ? counted : const {},
          now,
          startOfToday,
        );
      });

  Future<void> load() => v(() async {
        if (_loaded) return;

        final now = DateTime.now();
        final startOfToday =
            now.atStartOfDay(ref.read(preferenceProvider(startOfDayKey)));

        final mems = await _memRepository.shipOverdueCandidateIds(now: now);
        if (mems.isEmpty) return;
        ref.read(memEntitiesProvider.notifier).upsert(mems);

        final actCountsByMemId =
            await ref.read(actCountsByMemIdByDateProvider(now).notifier).load();

        _loaded = true;
        state = _overdueMems(
          ref.read(memEntitiesProvider),
          actCountsByMemId,
          now,
          startOfToday,
        );
      });

  List<MemEntity> _overdueMems(
    Iterable<MemEntity> mems,
    Map<int, int> periodCountByMemId,
    DateTime now,
    DateTime startOfToday,
  ) {
    final notifications = [
      for (final mem in mems)
        for (final notification
            in mem.repeatedNotifications ?? const <MemNotificationEntity>[])
          SavedMemNotificationEntityV1.fromEntityV2(notification),
    ];

    return MemsByNotifyAt.of(
      mems,
      notifications,
      startOfToday: startOfToday,
      periodCountByMemId: periodCountByMemId,
      include: (notifyAt) => notifyAt.isBefore(now),
    ).mems;
  }
}
