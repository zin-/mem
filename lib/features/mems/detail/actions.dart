import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/mem_client.dart';

import 'states.dart';

final saveMem =
    Provider.autoDispose.family<Future<DateTime?>, int?>((ref, memId) => v(
          () async {
            final link = ref.keepAlive();
            try {
              final (saved, nextNotifyAt) = await MemClient().save(
                ref.read(editingMemByMemIdProvider(memId)),
                ref.read(memItemsByMemIdProvider(memId)),
                ref.read(memNotificationsByMemIdProvider(memId)),
                ref.read(targetStateProvider(memId)).value,
                ref
                    .read(memRelationEntitiesByMemIdProvider(memId))
                    .value
                    ?.toList(),
              );

              if (!ref.mounted) return nextNotifyAt;

              if (memId == null) {
                ref
                    .read(editingMemByMemIdProvider(memId).notifier)
                    .updatedBy(saved.$1);
              }

              ref.read(memItemsProvider.notifier).upsertAll(
                    saved.$2,
                    (current, updating) =>
                        current.value.memId == updating.value.memId &&
                        current.value.type == updating.value.type,
                  );
              ref.read(memNotificationsProvider.notifier).upsertAll(
                    saved.$3 ?? [],
                    (tmp, item) =>
                        tmp is SavedMemNotificationEntityV1 &&
                        item is SavedMemNotificationEntityV1 &&
                        tmp.id == item.id,
                    removeWhere: (current) =>
                        current.value.memId == memId &&
                        current.value.isRepeatByDayOfWeek(),
                  );

              return nextNotifyAt;
            } finally {
              link.close();
            }
          },
          memId,
        ));

final removeMem = Provider.autoDispose.family<Future<bool> Function(), int?>(
  (ref, memId) => () => v(
        () async {
          if (memId != null) {
            final removedMemEntities = await ref
                .read(memEntitiesProvider.notifier)
                .removeAsync([memId]);

            for (var e in removedMemEntities) {
              ref.read(removedMemProvider(e.id).notifier).updatedBy(e);
              ref.read(removedMemItemsProvider(e.id).notifier).updatedBy(
                    ref.read(memItemsByMemIdProvider(e.id)),
                  );
              // TODO mem notificationsにも同様の処理が必要では？
            }

            return true;
          }

          return false;
        },
        memId,
      ),
);
