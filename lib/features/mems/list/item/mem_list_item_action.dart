import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mems_state.dart';

class MemListItemAction {
  static bool hasEnabledNotifications(WidgetRef ref, int memId) => ref
      .watch(memNotificationsByMemIdProvider(memId))
      .where(
        (e) => e is SavedMemNotificationEntityV1 && e.value.isEnabled(),
      )
      .isNotEmpty;

  static bool hasUndoneChildren(WidgetRef ref, MemId memId) => ref.watch(
        parentMemIdsWithUndoneChildrenProvider.select(
          (ids) => ids.contains(memId),
        ),
      );
}
