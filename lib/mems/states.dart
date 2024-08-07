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
import 'package:mem/repositories/mem_repository.dart';

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>>(
  (ref) => v(() => ListValueStateNotifier<Mem>([])),
);
final memItemsProvider =
    StateNotifierProvider<ListValueStateNotifier<MemItem>, List<MemItem>>(
  (ref) => v(
    () => ListValueStateNotifier([]),
  ),
);
final memNotificationsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemNotification>, List<MemNotification>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

final memByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMem?>, SavedMem?, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memsProvider).singleWhereOrNull(
            (element) => element is SavedMem ? element.id == memId : false,
          ) as SavedMem?,
      initializer: (current, notifier) => v(
        () async {
          if (memId != null) {
            final savedMem = await MemRepository().findOneBy(id: memId);
            ref.read(memsProvider.notifier).upsertAll(
              [if (savedMem != null) savedMem],
              (current, updating) =>
                  (current is SavedMem && updating is SavedMem)
                      ? current.id == updating.id
                      : true,
            );
          }
        },
        {'current': current, 'notifier': notifier},
      ),
    ),
    {"memId": memId},
  ),
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
    memId,
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
