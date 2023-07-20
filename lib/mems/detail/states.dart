import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/components/value_state_notifier.dart';

final memDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail>, MemDetail, int?>(
  (ref, memId) => v(
    () {
      return ValueStateNotifier(
        MemDetail(
          ref.watch(editingMemProvider(memId)),
          ref.watch(memItemsProvider(memId))!,
          ref.watch(memNotificationProvider(memId)),
        ),
      );
    },
  ),
);

final editingMemProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    () {
      final rawMemList = ref.read(rawMemListProvider);
      final memFromRawMemList =
          rawMemList?.singleWhereOrNull((element) => element.id == memId);

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
    () {
      final mem = ref.watch(editingMemProvider(memId));

      return ValueStateNotifier(mem.isArchived());
    },
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

final memNotificationProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemNotification?>,
        MemNotification?, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(null),
    memId,
  ),
);
