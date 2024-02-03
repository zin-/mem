import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem_notification_repository.dart';

final memDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail>, MemDetail, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      MemDetail(
        ref.watch(editingMemByMemIdProvider(memId)),
        ref.watch(memItemsByMemIdProvider(memId)),
        ref.watch(memNotificationsByMemIdProvider(memId)),
      ),
    ),
    memId,
  ),
);

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memByMemIdProvider(memId)) ?? Mem.defaultNew(),
    ),
    memId,
  ),
);

final memItemsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemItem>, List<MemItem>, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier(
      [
        MemItem.memo(memId),
      ],
      initialFuture: memId == null
          ? null
          : MemItemRepository().shipByMemId(memId).then(
                (value) => value.isEmpty ? [MemItem.memo(memId)] : value,
              ),
    ),
    memId,
  ),
);

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotification>, List<MemNotification>,
        int?>(
  (ref, memId) => v(
    () {
      final memRepeatedNotification = ref.watch(
          memNotificationsProvider.select((value) => value.singleWhereOrNull(
                (e) => e.memId == memId && e.type == MemNotificationType.repeat,
              )));
      final memAfterActStartedNotification = ref.watch(
          memNotificationsProvider.select((value) => value.singleWhereOrNull(
                (e) =>
                    e.memId == memId &&
                    e.type == MemNotificationType.afterActStarted,
              )));

      return ListValueStateNotifier(
        [
          if (memRepeatedNotification != null) memRepeatedNotification,
          if (memAfterActStartedNotification != null)
            memAfterActStartedNotification,
        ],
        initialFuture: memId == null
            ? Future.value([
                MemNotification.repeated(memId),
                MemNotification.afterActStarted(memId),
              ])
            : MemNotificationRepository().shipByMemId(memId).then(
                (value) {
                  return [
                    value.singleWhereOrNull(
                          (e) =>
                              e.memId == memId &&
                              e.type == MemNotificationType.repeat,
                        ) ??
                        MemNotification.repeated(memId),
                    value.singleWhereOrNull(
                          (e) =>
                              e.memId == memId &&
                              e.type == MemNotificationType.afterActStarted,
                        ) ??
                        MemNotification.afterActStarted(memId),
                  ];
                },
              ),
      );
    },
    {"memId": memId},
  ),
);
