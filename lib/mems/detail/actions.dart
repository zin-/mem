import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_item.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';

final loadMemItems =
    FutureProvider.autoDispose.family<List<SavedMemItem>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final memItems = await MemItemRepository().shipByMemId(memId);

        if (memItems.isNotEmpty) {
          ref
              .watch(memItemsProvider(memId).notifier)
              .updatedBy(memItems.toList());
        }

        return memItems.toList();
      }

      return [];
    },
    memId,
  ),
);
final loadMemNotificationsByMemId =
    FutureProvider.autoDispose.family<void, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final memNotifications =
            await MemNotificationRepository().shipByMemId(memId);

        if (memNotifications.isNotEmpty) {
          ref.watch(memNotificationsProvider.notifier).upsertAll(
                memNotifications,
                (tmp, item) =>
                    tmp is SavedMemNotification &&
                    item is SavedMemNotification &&
                    tmp.id == item.id,
              );
        }
      }
    },
    memId,
  ),
);

final saveMem =
    Provider.autoDispose.family<Future<MemDetail>, int?>((ref, memId) => v(
          () async {
            final saved = await MemService().save(
              ref.watch(memDetailProvider(memId)),
            );

            ref.read(memsProvider.notifier).upsertAll(
              [saved.mem],
              (tmp, item) => tmp is SavedMem && item is SavedMem
                  ? tmp.id == item.id
                  : false,
            );

            ref
                .read(editingMemByMemIdProvider(memId).notifier)
                .updatedBy(saved.mem);
            ref
                .read(memItemsProvider(memId).notifier)
                .updatedBy(saved.memItems);
            ref.read(memNotificationsProvider.notifier).upsertAll(
                  saved.notifications ?? [],
                  (tmp, item) =>
                      tmp is SavedMemNotification &&
                      item is SavedMemNotification &&
                      tmp.id == item.id,
                );

            return saved;
          },
          memId,
        ));

final archiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(memDetailProvider(memId)).mem as SavedMem;

      final archived = await MemService().archive(mem);

      ref
          .read(editingMemByMemIdProvider(memId).notifier)
          .updatedBy(archived.mem);
      ref.read(memsProvider.notifier).upsertAll(
          [archived.mem],
          (tmp, item) =>
              tmp is SavedMem && item is SavedMem ? tmp.id == item.id : false);

      return archived;
    },
    {'memId': memId},
  ),
);

final unarchiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(memDetailProvider(memId)).mem as SavedMem;

      final unarchived = await MemService().unarchive(mem);

      ref
          .read(editingMemByMemIdProvider(memId).notifier)
          .updatedBy(unarchived.mem);
      ref.read(memsProvider.notifier).upsertAll(
          [unarchived.mem],
          (tmp, item) =>
              tmp is SavedMem && item is SavedMem ? tmp.id == item.id : false);

      return unarchived;
    },
    {'memId': memId},
  ),
);

final removeMem = Provider.autoDispose.family<Future<bool>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final removeSuccess = await MemService().remove(memId);

        ref
            .read(removedMemProvider(memId).notifier)
            .updatedBy(ref.read(memByMemIdProvider(memId)));
        ref.read(removedMemItemsProvider(memId).notifier).updatedBy(
              ref.read(memItemsProvider(memId)),
            );

        ref.read(memsProvider.notifier).removeWhere(
            (element) => element is SavedMem && element.id == memId);

        return removeSuccess;
      }

      return false;
    },
    memId,
  ),
);
