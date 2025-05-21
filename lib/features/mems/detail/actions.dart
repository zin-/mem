import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_detail.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/states.dart';

import 'states.dart';

final saveMem =
    Provider.autoDispose.family<Future<MemDetail>, int?>((ref, memId) => v(
          () async {
            final saved = await ref.read(memEntitiesProvider.notifier).save(
                  ref.read(editingMemByMemIdProvider(memId)),
                  ref.read(memItemsByMemIdProvider(memId)),
                  ref.read(memNotificationsByMemIdProvider(memId)),
                  ref.read(targetStateProvider(memId)).value,
                );

            if (memId == null) {
              ref
                  .read(editingMemByMemIdProvider(memId).notifier)
                  .updatedBy(saved.mem);
            }

            ref.read(memItemsProvider.notifier).upsertAll(
                  saved.memItems,
                  (current, updating) =>
                      current.value.memId == updating.value.memId &&
                      current.value.type == updating.value.type,
                );
            ref.read(memNotificationsProvider.notifier).upsertAll(
                  saved.notifications ?? [],
                  (tmp, item) =>
                      tmp is SavedMemNotificationEntityV2 &&
                      item is SavedMemNotificationEntityV2 &&
                      tmp.id == item.id,
                  removeWhere: (current) =>
                      current.value.memId == memId &&
                      current.value.isRepeatByDayOfWeek(),
                );

            return saved;
          },
          memId,
        ));

final removeMem = Provider.autoDispose.family<Future<bool>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final removeSuccess = await MemClient().remove(memId);

        final mem = ref.read(memByMemIdProvider(memId));
        ref.read(removedMemProvider(memId).notifier).updatedBy(mem);
        ref.read(removedMemItemsProvider(memId).notifier).updatedBy(
              ref.read(memItemsByMemIdProvider(memId)),
            );
        // TODO mem notificationsにも同様の処理が必要では？

        ref.read(memEntitiesProvider.notifier).remove([memId]);

        return removeSuccess;
      }

      return false;
    },
    memId,
  ),
);
