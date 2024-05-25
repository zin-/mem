import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memByMemIdProvider(memId)) ?? Mem.defaultNew(),
    ),
    {"memId": memId},
  ),
);

final memItemsByMemIdProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItem>, List<MemItem>, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier(
      [
        ref.watch(
              memItemsProvider.select(
                (value) => value.singleWhereOrNull(
                  (element) => element.memId == memId,
                ),
              ),
            ) ??
            MemItem.memo(memId),
      ],
      initialFuture: memId == null
          ? null
          : MemItemRepository().shipByMemId(memId).then(
                (value) => value.isEmpty ? [MemItem.memo(memId)] : value,
              ),
    ),
    {"memId": memId},
  ),
);

final memRepeatedNotificationByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemNotification>, MemNotification, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier<MemNotification>(
      ref.watch(
            memNotificationsProvider.select(
              (value) => value
                  .where(
                    (element) => element.memId == memId && element.isRepeated(),
                  )
                  .singleOrNull,
            ),
          ) ??
          MemNotification.repeated(memId),
      initializer: (current, notifier) => v(
        () async {
          if (memId != null && current is! SavedMemNotification) {
            ref.read(memNotificationsProvider.notifier).upsertAll(
                  await MemNotificationRepository().shipByMemId(memId),
                  (current, updating) =>
                      current.memId == updating.memId &&
                      current.type == updating.type,
                );
          }
        },
        {'current': current, 'notifier': notifier},
      ),
    ),
    {'memId': memId},
  ),
);

final memRepeatByNDayNotificationByMemIdProvider = StateNotifierProvider
    .autoDispose
    .family<ValueStateNotifier<MemNotification>, MemNotification, int?>(
  (ref, memId) => v(
    () {
      final notification = ref.watch(
        memNotificationsProvider.select(
          (value) => value
              .where((element) =>
                  element.memId == memId && element.isRepeatByNDay())
              .singleOrNull,
        ),
      );

      return ValueStateNotifier(
        notification ?? MemNotification.repeatByNDay(memId),
        initialFuture: memId == null
            ? Future.value(
                MemNotification.repeatByNDay(memId),
              )
            : MemNotificationRepository().shipByMemId(memId).then(
                  (value) =>
                      value.singleWhereOrNull(
                        (e) => e.memId == memId && e.isRepeatByNDay(),
                      ) ??
                      MemNotification.repeatByNDay(memId),
                ),
      );
    },
    memId,
  ),
);

final memAfterActStartedNotificationByMemIdProvider = StateNotifierProvider
    .autoDispose
    .family<ValueStateNotifier<MemNotification>, MemNotification, int?>(
  (ref, memId) => v(
    () {
      final notification = ref.watch(
        memNotificationsProvider.select(
          (value) => value
              .where((element) =>
                  element.memId == memId && element.isAfterActStarted())
              .singleOrNull,
        ),
      );

      return ValueStateNotifier(
        notification ?? MemNotification.afterActStarted(memId),
        initialFuture: memId == null
            ? Future.value(
                MemNotification.afterActStarted(memId),
              )
            : MemNotificationRepository().shipByMemId(memId).then(
                  (value) =>
                      value.singleWhereOrNull(
                        (e) => e.memId == memId && e.isAfterActStarted(),
                      ) ??
                      MemNotification.afterActStarted(memId),
                ),
      );
    },
    memId,
  ),
);

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotification>, List<MemNotification>,
        int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier(
      [
        ref.watch(memRepeatedNotificationByMemIdProvider(memId)),
        ref.watch(memRepeatByNDayNotificationByMemIdProvider(memId)),
        ref.watch(memAfterActStartedNotificationByMemIdProvider(memId)),
      ],
    ),
    {"memId": memId},
  ),
);
