import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/mem_item.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem_notification.dart';
import 'package:mem/repositories/mem_notification_repository.dart';

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemV1>, MemV1, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memByMemIdProvider(memId)) ?? MemV1.defaultNew(),
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
      initializer: (current, notifier) async {
        if (memId != null) {
          ref.read(memItemsProvider.notifier).upsertAll(
                await MemItemRepository()
                    .ship(memId: memId)
                    .then((v) => v.map((e) => e.toV1())),
                (current, updating) =>
                    current is SavedMemItem &&
                    updating is SavedMemItem &&
                    current.id == updating.id,
              );
        }
      },
    ),
    {"memId": memId},
  ),
);

final memRepeatByNDayNotificationByMemIdProvider = StateNotifierProvider
    .autoDispose
    .family<ValueStateNotifier<MemNotification>, MemNotification, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(
        memNotificationsByMemIdProvider(memId).select(
          (value) => value
              .where(
                (element) => element.isRepeatByNDay(),
              )
              .single,
        ),
      ),
    ),
    {'memId': memId},
  ),
);

final memAfterActStartedNotificationByMemIdProvider = StateNotifierProvider
    .autoDispose
    .family<ValueStateNotifier<MemNotification>, MemNotification, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(
        memNotificationsByMemIdProvider(memId).select(
          (value) => value
              .where(
                (element) => element.isAfterActStarted(),
              )
              .single,
        ),
      ),
    ),
    {'memId': memId},
  ),
);

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotification>, List<MemNotification>,
        int?>(
  (ref, memId) => v(
    () {
      final memNotificationsByMemId = ref.watch(memNotificationsProvider.select(
          (memNotifications) => memNotifications
              .where((memNotification) => memNotification.memId == memId)));

      return ListValueStateNotifier(
        [
          ...memNotificationsByMemId,
          if (memNotificationsByMemId.every((element) => !element.isRepeated()))
            MemNotification.repeated(memId),
          if (memNotificationsByMemId
              .every((element) => !element.isRepeatByNDay()))
            MemNotification.repeatByNDay(memId),
          if (memNotificationsByMemId
              .every((element) => !element.isAfterActStarted()))
            MemNotification.afterActStarted(memId),
        ],
        initializer: (current, notifier) => v(
          () async {
            if (memId != null &&
                current.whereType<SavedMemNotification>().isEmpty) {
              ref.read(memNotificationsProvider.notifier).upsertAll(
                    await MemNotificationRepository()
                        .ship(memId: memId)
                        .then((value) => value.map((e) => e.toV1())),
                    (current, updating) => updating.isRepeatByDayOfWeek()
                        ? current.memId == updating.memId &&
                            current.type == updating.type &&
                            current.time == updating.time
                        : current.memId == updating.memId &&
                            current.type == updating.type,
                  );
            }
          },
          {'current': current},
        ),
      );
    },
    {"memId": memId},
  ),
);
