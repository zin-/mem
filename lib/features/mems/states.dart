import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

final memItemsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemItemEntity>, List<MemItemEntity>>(
  (ref) => v(
    () => ListValueStateNotifier([]),
  ),
);
final memNotificationsProvider = StateNotifierProvider<
    ListValueStateNotifier<MemNotificationEntity>, List<MemNotificationEntity>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

final memByMemIdProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedMemEntityV1?>, SavedMemEntityV1?, int?>(
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
              await ref.read(memEntitiesProvider.notifier).loadByMemId(memId);
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

final removedMemDetailProvider = StateNotifierProvider.autoDispose.family<
    ValueStateNotifier<
        (
          MemEntityV1,
          List<MemItemEntity>,
          List<MemNotificationEntity>?,
          TargetEntity?,
          List<MemRelationEntity>?
        )?>,
    (
      MemEntityV1,
      List<MemItemEntity>,
      List<MemNotificationEntity>?,
      TargetEntity?,
      List<MemRelationEntity>?
    )?,
    int>(
  (ref, memId) => v(
    () {
      final removedMem = ref.watch(removedMemProvider(memId));
      final removedMemItems = ref.watch(removedMemItemsProvider(memId));
      final removedMemNotifications =
          ref.watch(memNotificationsByMemIdProvider(memId));
      final target = ref.watch(targetStateProvider(memId)).value;
      final removedMemRelations =
          ref.watch(memRelationEntitiesByMemIdProvider(memId)).value;

      return ValueStateNotifier(
        removedMem != null
            ? (
                removedMem,
                removedMemItems ?? [],
                removedMemNotifications,
                target,
                removedMemRelations?.toList(),
              )
            : null,
      );
    },
    memId,
  ),
);
final removedMemProvider = StateNotifierProvider.family<
    ValueStateNotifier<MemEntityV1?>, MemEntityV1?, int>(
  (ref, memId) => v(
    () => ValueStateNotifier<MemEntityV1?>(null),
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
