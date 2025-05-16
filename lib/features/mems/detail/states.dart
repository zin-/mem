import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/states.dart';

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemEntityV2>, MemEntityV2, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.watch(memByMemIdProvider(memId));
      return ValueStateNotifier(
        mem ?? MemEntityV2(Mem("", null, null)),
      );
    },
    {"memId": memId},
  ),
);

final memItemsByMemIdProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItemEntityV2>, List<MemItemEntityV2>, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier(
      [
        ref.watch(
              memItemsProvider.select(
                (value) => value.singleWhereOrNull(
                  (element) => element.value.memId == memId,
                ),
              ),
            ) ??
            MemItemEntityV2(MemItem(memId, MemItemType.memo, ""))
      ],
      initializer: (current, notifier) async {
        if (memId != null) {
          ref.read(memItemsProvider.notifier).upsertAll(
                await MemItemRepositoryV2().ship(memId: memId),
                (current, updating) =>
                    current is SavedMemItemEntityV2 &&
                    updating is SavedMemItemEntityV2 &&
                    current.id == updating.id,
              );
        }
      },
    ),
    {'memId': memId},
  ),
);

final memRepeatByNDayNotificationByMemIdProvider =
    StateNotifierProvider.autoDispose.family<
        ValueStateNotifier<MemNotificationEntityV2>,
        MemNotificationEntityV2,
        int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(
        memNotificationsByMemIdProvider(memId).select(
          (value) => value
              .where(
                (element) => element.value.isRepeatByNDay(),
              )
              .single,
        ),
      ),
    ),
    {'memId': memId},
  ),
);

final memAfterActStartedNotificationByMemIdProvider =
    StateNotifierProvider.autoDispose.family<
        ValueStateNotifier<MemNotificationEntityV2>,
        MemNotificationEntityV2,
        int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(
        memNotificationsByMemIdProvider(memId).select(
          (value) => value
              .where(
                (element) => element.value.isAfterActStarted(),
              )
              .single,
        ),
      ),
    ),
    {'memId': memId},
  ),
);

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotificationEntityV2>,
        List<MemNotificationEntityV2>, int?>(
  (ref, memId) => v(
    () {
      final memNotificationsByMemId = ref.watch(
        memNotificationsProvider.select(
          (memNotifications) => memNotifications.where(
            (e) => e.value.memId == memId,
          ),
        ),
      );

      return ListValueStateNotifier(
        [
          ...memNotificationsByMemId,
          if (memNotificationsByMemId
              .every((element) => !element.value.isRepeated()))
            MemNotificationEntityV2(MemNotification.by(
              memId,
              MemNotificationType.repeat,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isRepeatByNDay()))
            MemNotificationEntityV2(MemNotification.by(
              memId,
              MemNotificationType.repeatByNDay,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isAfterActStarted()))
            MemNotificationEntityV2(MemNotification.by(
              memId,
              MemNotificationType.afterActStarted,
              null,
              null,
            )),
        ],
        initializer: (current, notifier) => v(
          () async {
            if (memId != null &&
                current.whereType<SavedMemNotificationEntityV2>().isEmpty) {
              ref.read(memNotificationsProvider.notifier).upsertAll(
                    await MemNotificationRepositoryV2().ship(memId: memId),
                    (current, updating) => updating.value.isRepeatByDayOfWeek()
                        ? current.value.memId == updating.value.memId &&
                            current.value.type == updating.value.type &&
                            current.value.time == updating.value.time
                        : current.value.memId == updating.value.memId &&
                            current.value.type == updating.value.type,
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
