import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_item_entity.dart';
import 'package:mem/repositories/mem_repository.dart';

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<MemV1>, List<MemV1>>(
  (ref) => v(() => ListValueStateNotifier<MemV1>([])),
);
final memItemsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>>(
  (ref) => v(
    () => ListValueStateNotifier([]),
  ),
);
final memNotificationsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemNotification>, List<MemNotification>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

final memByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMemV1?>, SavedMemV1?, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memsProvider).singleWhereOrNull(
            (element) => element is SavedMemV1 ? element.id == memId : false,
          ) as SavedMemV1?,
      initializer: (current, notifier) => v(
        () async {
          if (memId != null) {
            final savedMem = await MemRepository()
                .ship(id: memId)
                .then((value) => value.singleOrNull?.toV1());
            ref.read(memsProvider.notifier).upsertAll(
              [if (savedMem != null) savedMem],
              (current, updating) =>
                  (current is SavedMemV1 && updating is SavedMemV1)
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
    StateNotifierProvider.family<ValueStateNotifier<MemV1?>, MemV1?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<MemV1?>(null),
    memId,
  ),
);
final removedMemItemsProvider = StateNotifierProvider.family<
    ValueStateNotifier<List<MemItemEntity>?>, List<MemItemEntity>?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier(null),
    memId,
  ),
);
