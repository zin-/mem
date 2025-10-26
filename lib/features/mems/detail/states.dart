import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/features/mems/mem_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

part 'states.g.dart';

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemEntity>, MemEntity, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.watch(memByMemIdProvider(memId));
      return ValueStateNotifier(
        mem ?? MemEntity(Mem(null, "", null, null)),
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
                  (element) => element.value.memId == memId,
                ),
              ),
            ) ??
            MemItemEntity(MemItem(memId, MemItemType.memo, ""))
      ],
      initializer: (current, notifier) async {
        if (memId != null) {
          final items = await MemItemRepository().ship(memId: memId);
          if (notifier.mounted) {
            ref.read(memItemsProvider.notifier).upsertAll(
                  items,
                  (current, updating) =>
                      current is SavedMemItemEntity &&
                      updating is SavedMemItemEntity &&
                      current.id == updating.id,
                );
          }
        }
      },
    ),
    {'memId': memId},
  ),
);

final memRepeatByNDayNotificationByMemIdProvider =
    StateNotifierProvider.autoDispose.family<
        ValueStateNotifier<MemNotificationEntity>, MemNotificationEntity, int?>(
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
        ValueStateNotifier<MemNotificationEntity>, MemNotificationEntity, int?>(
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
    .family<ListValueStateNotifier<MemNotificationEntity>,
        List<MemNotificationEntity>, int?>(
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
            MemNotificationEntity(MemNotification.by(
              memId,
              MemNotificationType.repeat,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isRepeatByNDay()))
            MemNotificationEntity(MemNotification.by(
              memId,
              MemNotificationType.repeatByNDay,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isAfterActStarted()))
            MemNotificationEntity(MemNotification.by(
              memId,
              MemNotificationType.afterActStarted,
              null,
              null,
            )),
        ],
        initializer: (current, notifier) => v(
          () async {
            if (memId != null &&
                current.whereType<SavedMemNotificationEntity>().isEmpty) {
              final notifications =
                  await MemNotificationRepository().ship(memId: memId);
              if (notifier.mounted) {
                ref.read(memNotificationsProvider.notifier).upsertAll(
                      notifications,
                      (current, updating) =>
                          updating.value.isRepeatByDayOfWeek()
                              ? current.value.memId == updating.value.memId &&
                                  current.value.type == updating.value.type &&
                                  current.value.time == updating.value.time
                              : current.value.memId == updating.value.memId &&
                                  current.value.type == updating.value.type,
                    );
              }
            }
          },
          {'current': current},
        ),
      );
    },
    {"memId": memId},
  ),
);

@riverpod
class MemState extends _$MemState {
  // TODO Mem自体がMemNotificaitonなどを持つようになったら
  // そこへのアクセスを持って取得しに行くようにする
  @override
  Future<Mem> build(int? memId) async => v(
        () async => await MemStore().serveOneBy(memId),
        {'memId': memId},
      );
}
