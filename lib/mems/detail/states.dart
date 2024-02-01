import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/states.dart';

final memDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail>, MemDetail, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      MemDetail(
        ref.watch(editingMemByMemIdProvider(memId)),
        ref.watch(memItemsProvider(memId))!,
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

final memItemsProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemItem>, List<MemItem>, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier([
      MemItem(memId, MemItemType.memo, ''),
    ]),
    memId,
  ),
);

final memNotificationsByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemNotification>, List<MemNotification>,
        int?>(
  (ref, memId) => v(
    () {
      final memNotificationsByMemId = ref
          .watch(memNotificationsProvider)
          .where((element) => element.memId == memId);
      final memRepeatedNotification = memNotificationsByMemId.singleWhereOrNull(
          (element) => element.type == MemNotificationType.repeat);
      final memAfterActStartedNotification =
          memNotificationsByMemId.singleWhereOrNull(
              (element) => element.type == MemNotificationType.afterActStarted);

      return ListValueStateNotifier(
        [
          memRepeatedNotification ?? MemNotification.repeated(memId),
          memAfterActStartedNotification ??
              MemNotification.afterActStarted(memId),
        ],
      );
    },
    {"memId": memId},
  ),
);
