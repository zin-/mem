import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/mems/states.dart';

final memDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail>, MemDetail, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      MemDetail(
        ref.watch(editingMemProvider(memId)),
        ref.watch(memItemsProvider(memId))!,
        ref
            .watch(memNotificationsByMemIdProvider(memId))
            ?.map((e) => e.toV1())
            .toList(),
      ),
    ),
    memId,
  ),
);

final editingMemProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    () {
      final rawMemList = ref.watch(memsProvider);
      final memFromRawMemList = rawMemList?.singleWhereOrNull(
          (element) => element is SavedMem ? element.id == memId : false);

      if (memId != null && rawMemList == null) {
        MemRepository().shipById(memId).then((value) {
          ref.read(memsProvider.notifier).upsertAll(
              [value],
              (tmp, item) => tmp is SavedMem && item is SavedMem
                  ? tmp.id == item.id
                  : false);
        });
      }

      return ValueStateNotifier(
        memFromRawMemList ?? Mem('', null, null),
      );
    },
    memId,
  ),
);

final memIsArchivedProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<bool>, bool, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.watch(memDetailProvider(memId)).mem;
      return ValueStateNotifier((mem is SavedMem) ? mem.isArchived : false);
    },
    memId,
  ),
);

final memItemsProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemItem>, List<MemItem>?, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier([
      MemItem(memId, MemItemType.memo, ''),
    ]),
    memId,
  ),
);

MemNotificationV2 _initialRepeatMemNotification(int? memId) =>
    MemNotificationV2(
      memId,
      MemNotificationType.repeat,
      null,
      'Repeat',
    );

MemNotificationV2 _initialAfterActStartedMemNotification(int? memId) =>
    MemNotificationV2(
      memId,
      MemNotificationType.afterActStarted,
      null,
      'Finish?',
    );

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotificationV2>, List<MemNotificationV2>?,
        int?>(
  (ref, memId) => v(
    () {
      final memNotificationsByMemId = ref
          .watch(memNotificationsProvider)
          ?.where((element) => element.memId == memId);
      final memRepeatedNotification =
          memNotificationsByMemId?.singleWhereOrNull(
              (element) => element.type == MemNotificationType.repeat);
      final memAfterActStartedNotification =
          memNotificationsByMemId?.singleWhereOrNull(
              (element) => element.type == MemNotificationType.afterActStarted);

      return ListValueStateNotifier(
        [
          memRepeatedNotification == null
              ? _initialRepeatMemNotification(memId)
              : MemNotificationV2.fromV1(memRepeatedNotification),
          memAfterActStartedNotification == null
              ? _initialAfterActStartedMemNotification(memId)
              : MemNotificationV2.fromV1(memAfterActStartedNotification),
        ],
      );
    },
    memId,
  ),
);
