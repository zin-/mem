import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/mems/mem_detail.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';
import 'package:mem/mems/mem_repository.dart';

final memsProvider =
    StateNotifierProvider<ListValueStateNotifier<MemEntity>, List<MemEntity>>(
  (ref) => v(() => ListValueStateNotifier<MemEntity>([])),
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
    .family<ValueStateNotifier<SavedMemEntity?>, SavedMemEntity?, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(
      ref.watch(memsProvider).singleWhereOrNull(
            (element) =>
                element is SavedMemEntity ? element.id == memId : false,
          ) as SavedMemEntity?,
      initializer: (current, notifier) => v(
        () async {
          if (memId != null) {
            final savedMem = await MemRepositoryV2()
                .ship(id: memId)
                .then((value) => value.singleOrNull?.toV1());
            ref.read(memsProvider.notifier).upsertAll(
              [if (savedMem != null) savedMem],
              (current, updating) =>
                  (current is SavedMemEntity && updating is SavedMemEntity)
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
final removedMemProvider = StateNotifierProvider.family<
    ValueStateNotifier<MemEntity?>, MemEntity?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<MemEntity?>(null),
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
