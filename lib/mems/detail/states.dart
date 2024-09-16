import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_entity.dart';
import 'package:mem/repositories/mem_notification_entity.dart';
import 'package:mem/repositories/mem_notification_repository.dart';

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemEntity>, MemEntity, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.watch(memByMemIdProvider(memId));
      return ValueStateNotifier(
        mem ?? MemEntity("", null, null),
      );
    },
    {"memId": memId},
  ),
);

final memItemsByMemIdProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>, int?>(
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
            MemItemEntity(memId, MemItemType.memo, "")
      ],
      initializer: (current, notifier) async {
        if (memId != null) {
          ref.read(memItemsProvider.notifier).upsertAll(
                await MemItemRepository().ship(memId: memId),
                (current, updating) =>
                    current is SavedMemItemEntity &&
                    updating is SavedMemItemEntity &&
                    current.id == updating.id,
              );
        }
      },
    ),
    {'memId': memId},
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
            MemNotificationEntity.initialByType(
                memId, MemNotificationType.repeat),
          if (memNotificationsByMemId
              .every((element) => !element.isRepeatByNDay()))
            MemNotificationEntity.initialByType(
                memId, MemNotificationType.repeatByNDay),
          if (memNotificationsByMemId
              .every((element) => !element.isAfterActStarted()))
            MemNotificationEntity.initialByType(
                memId, MemNotificationType.afterActStarted),
        ],
        initializer: (current, notifier) => v(
          () async {
            if (memId != null &&
                current.whereType<SavedMemNotificationEntity>().isEmpty) {
              ref.read(memNotificationsProvider.notifier).upsertAll(
                    await MemNotificationRepository().ship(memId: memId),
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
