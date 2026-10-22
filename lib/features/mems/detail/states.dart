import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/features/mems/mem_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/states.dart';

part 'states.g.dart';

void listenMemInitialLoad(
  Ref ref,
  int? memId,
  ValueStateNotifier<MemViewData> notifier,
) {
  ref.listen<MemEntity?>(
    memByMemIdProvider(memId),
    (prev, next) {
      if (prev == null && next != null) {
        notifier.updatedBy(MemViewData.fromEntityV2(next));
      }
    },
  );
}

void listenMemItemsInitialLoad(
  Ref ref,
  int? memId,
  ListValueStateNotifier<MemItemEntityV1> notifier,
) {
  ref.listen<List<SavedMemItemEntityV1>>(
    savedMemItemsByMemIdProvider(memId),
    (prev, next) {
      if ((prev == null || prev.isEmpty) && next.isNotEmpty) {
        notifier.updatedBy(List<MemItemEntityV1>.of(next));
      }
    },
  );
}

final editingMemByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemViewData>, MemViewData, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.read(memByMemIdProvider(memId));
      final notifier = ValueStateNotifier(
        mem == null ? MemViewData.newMem() : MemViewData.fromEntityV2(mem),
      );

      listenMemInitialLoad(ref, memId, notifier);

      return notifier;
    },
    {"memId": memId},
  ),
);

final memItemsByMemIdProvider = StateNotifierProvider.autoDispose.family<
    ListValueStateNotifier<MemItemEntityV1>, List<MemItemEntityV1>, int?>(
  (ref, memId) => v(
    () {
      final saved = ref.read(savedMemItemsByMemIdProvider(memId));
      final notifier = ListValueStateNotifier(
        saved.isEmpty
            ? [MemItemEntityV1(MemItem(memId, MemItemType.memo, ""))]
            : List<MemItemEntityV1>.of(saved),
      );

      listenMemItemsInitialLoad(ref, memId, notifier);

      return notifier;
    },
    {'memId': memId},
  ),
);

final memRepeatByNDayNotificationByMemIdProvider =
    StateNotifierProvider.autoDispose.family<
        ValueStateNotifier<MemNotificationEntityV1>,
        MemNotificationEntityV1,
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
        ValueStateNotifier<MemNotificationEntityV1>,
        MemNotificationEntityV1,
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
    .family<ListValueStateNotifier<MemNotificationEntityV1>,
        List<MemNotificationEntityV1>, int?>(
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
            MemNotificationEntityV1(MemNotification.by(
              memId,
              MemNotificationType.repeat,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isRepeatByNDay()))
            MemNotificationEntityV1(MemNotification.by(
              memId,
              MemNotificationType.repeatByNDay,
              null,
              null,
            )),
          if (memNotificationsByMemId
              .every((element) => !element.value.isAfterActStarted()))
            MemNotificationEntityV1(MemNotification.by(
              memId,
              MemNotificationType.afterActStarted,
              null,
              null,
            )),
        ],
        initializer: (current, notifier) => v(
          () async {
            if (memId != null &&
                current.whereType<SavedMemNotificationEntityV1>().isEmpty) {
              final notifications =
                  await MemNotificationRepository().ship(memId: memId);
              if (notifier.mounted) {
                ref.read(memNotificationsProvider.notifier).upsertAll(
                      notifications
                          .map((e) =>
                              SavedMemNotificationEntityV1.fromEntityV2(e))
                          .toList(),
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
