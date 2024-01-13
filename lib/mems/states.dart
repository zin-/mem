import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>?>(
  (ref) => v(() => ListValueStateNotifier<Mem>(null)),
);
final memProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMem?>, SavedMem?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref
              .read(memsProvider)
              ?.singleWhere((mem) => mem is SavedMem && mem.id == memId)
          as SavedMem?,
    ),
    {"memId": memId},
  ),
);

final memByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMem?>, SavedMem?, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.read(memsProvider)?.singleWhereOrNull(
            (element) => element is SavedMem ? element.id == memId : false,
          ) as SavedMem?,
    ),
    memId,
  ),
);

final memNotificationsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemNotification>, List<MemNotification>?>(
  (ref) => v(() => ListValueStateNotifier(null)),
);

final removedMemDetailProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<MemDetail?>, MemDetail?, int>(
  (ref, memId) => v(
    () {
      final removedMem = ref.watch(removedMemProvider(memId));
      final removedMemItems = ref.watch(removedMemItemsProvider(memId));

      MemDetail? removedMemDetail;
      if (removedMem != null && removedMemItems != null) {
        removedMemDetail = MemDetail(
          removedMem,
          removedMemItems,
        );
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
    () => ValueStateNotifier(null),
    memId,
  ),
);
