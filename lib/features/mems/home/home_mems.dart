import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

typedef SelectHomeMems = List<MemEntity> Function(
  Iterable<MemEntity> mems,
  Iterable<SavedMemNotificationEntityV1> savedMemNotifications, {
  required DateTime now,
  required DateTime startOfToday,
  Map<int, int> periodCountByMemId,
});

class HomeMems {
  HomeMems._();

  static List<MemEntity> of(Ref ref, SelectHomeMems select) {
    ref.listen(loadMemListProvider, (_, __) {});

    final mems = ref.watch(memEntitiesProvider);
    final savedMemNotifications = ref.watch(savedMemNotificationsProvider);
    final periodCountByMemId =
        ref.watch(listPeriodCountByMemIdProvider).value ?? const {};
    final startOfToday = DateTimeExt.startOfToday(
      ref.watch(preferenceProvider(startOfDayKey)),
    );

    return v(
      () => select(
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
  }
}
