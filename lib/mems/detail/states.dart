import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/states.dart';

final memDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail>, MemDetail, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      MemDetail(
        ref.watch(editingMemProvider(memId)),
        ref.watch(memItemsProvider(memId))!,
        ref.watch(memNotificationsProvider(memId)),
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
      final memFromRawMemList =
          rawMemList?.singleWhereOrNull((element) => element.id == memId);

      if (memId != null && rawMemList == null) {
        MemRepository().shipById(memId).then((value) {
          ref
              .read(memsProvider.notifier)
              .upsertAll([value], (tmp, item) => tmp.id == item.id);
        });
      }

      return ValueStateNotifier(
        memFromRawMemList ?? Mem(name: ''),
      );
    },
    memId,
  ),
);

final memIsArchivedProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<bool>, bool, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
        ref.watch(memDetailProvider(memId)).mem.isArchived()),
    memId,
  ),
);

final memItemsProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemItem>, List<MemItem>?, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier([
      MemItem(memId: memId, type: MemItemType.memo, value: ''),
    ]),
    memId,
  ),
);

final memNotificationsProvider = StateNotifierProvider.autoDispose.family<
    ListValueStateNotifier<MemNotification>, List<MemNotification>?, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier([
      MemNotification(
        MemNotificationType.repeat,
        null,
        'Repeat',
        memId: memId,
      ),
      MemNotification(
        MemNotificationType.afterActStarted,
        null,
        'Finish?',
        memId: memId,
      ),
    ]),
    memId,
  ),
);
