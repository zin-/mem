import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_client.dart';
import 'package:mem/mems/mem_detail.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/states.dart';

import 'states.dart';

final _memClient = MemClient();

final saveMem =
    Provider.autoDispose.family<Future<MemDetail>, int?>((ref, memId) => v(
          () async {
            final saved = await _memClient.save(
              ref.read(editingMemByMemIdProvider(memId)),
              ref.read(memItemsByMemIdProvider(memId)),
              ref.read(memNotificationsByMemIdProvider(memId)),
            );

            ref.read(memsProvider.notifier).upsertAll(
              [saved.mem],
              (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
                  ? tmp.id == item.id
                  : false,
            );

            ref
                .read(editingMemByMemIdProvider(memId).notifier)
                .updatedBy(saved.mem);
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
                  removeWhere: (current) => current.value.isRepeatByDayOfWeek(),
                );

            return saved;
          },
          memId,
        ));

final archiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final archived = await _memClient.archive(
        ref.read(memByMemIdProvider(memId))!,
      );

      ref
          .read(editingMemByMemIdProvider(memId).notifier)
          .updatedBy(archived.mem);
      ref.read(memsProvider.notifier).upsertAll(
          [archived.mem],
          (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
              ? tmp.id == item.id
              : false);

      return archived;
    },
    {'memId': memId},
  ),
);

final unarchiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final unarchived = await _memClient.unarchive(
        ref.read(memByMemIdProvider(memId))!,
      );

      ref
          .read(editingMemByMemIdProvider(memId).notifier)
          .updatedBy(unarchived.mem);
      ref.read(memsProvider.notifier).upsertAll(
          [unarchived.mem],
          (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
              ? tmp.id == item.id
              : false);

      return unarchived;
    },
    {'memId': memId},
  ),
);

final removeMem = Provider.autoDispose.family<Future<bool>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final removeSuccess = await _memClient.remove(memId);

        final mem = ref.read(memByMemIdProvider(memId));
        ref.read(removedMemProvider(memId).notifier).updatedBy(mem);
        ref.read(removedMemItemsProvider(memId).notifier).updatedBy(
              ref.read(memItemsByMemIdProvider(memId)),
            );
        // TODO mem notificationsにも同様の処理が必要では？

        ref.read(memsProvider.notifier).removeWhere(
              (element) => element is SavedMemEntityV2 && element.id == memId,
            );

        return removeSuccess;
      }

      return false;
    },
    memId,
  ),
);
