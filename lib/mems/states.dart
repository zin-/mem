import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>?>(
        (ref) => v(() => ListValueStateNotifier<Mem>(null)));
final memNotificationsProvider = StateNotifierProvider<
        ListValueStateNotifier<MemNotification>, List<MemNotification>?>(
    (ref) => v(() => ListValueStateNotifier<MemNotification>(null)));

final removedMemDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail?>, MemDetail?, int>(
  (ref, memId) => v(
    () {
      final removedMem = ref.watch(removedMemProvider(memId));
      final removedMemItems = ref.watch(removedMemItemsProvider(memId));

      MemDetail? removedMemDetail;
      if (removedMem != null && removedMemItems != null) {
        removedMemDetail =
            MemDetail(SavedMemV2.fromV1(removedMem), removedMemItems);
      } else {
        removedMemDetail = null;
      }

      return ValueStateNotifier(removedMemDetail);
    },
  ),
);
final removedMemProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<Mem?>(null),
    memId,
  ),
);
final removedMemItemsProvider = StateNotifierProvider.family<
    ValueStateNotifier<List<MemItem>?>, List<MemItem>?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<List<MemItem>?>(null),
    memId,
  ),
);
