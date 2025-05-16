import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/features/mems/mem_detail.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';

final memsProvider = StateNotifierProvider<ListValueStateNotifier<MemEntityV2>,
    List<MemEntityV2>>(
  (ref) => v(() => ListValueStateNotifier<MemEntityV2>([])),
);
final memItemsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemItemEntityV2>, List<MemItemEntityV2>>(
  (ref) => v(
    () => ListValueStateNotifier([]),
  ),
);
final memNotificationsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemNotificationEntityV2>,
    List<MemNotificationEntityV2>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

final memByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMemEntityV2?>, SavedMemEntityV2?, int?>(
  (ref, memId) => v(
    () {
      final mem = ref.watch(
        memEntitiesProvider.select(
          (v) => v.singleWhereOrNull(
            (e) => e.id == memId,
          ),
        ),
      );

      return ValueStateNotifier(
        mem,
        initializer: (current, notifier) => v(
          () async {
            if (mem == null && memId != null) {
              ref.read(memEntitiesProvider.notifier).upsert(
                    await MemRepositoryV2().ship(id: memId),
                  );
            }
          },
          {
            'current': current,
            'notifier': notifier,
          },
        ),
      );
    },
    {
      'memId': memId,
    },
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
    ValueStateNotifier<MemEntityV2?>, MemEntityV2?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<MemEntityV2?>(null),
    memId,
  ),
);
final removedMemItemsProvider = StateNotifierProvider.family<
    ValueStateNotifier<List<MemItemEntityV2>?>, List<MemItemEntityV2>?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier(null),
    memId,
  ),
);
