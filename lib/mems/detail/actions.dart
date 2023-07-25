import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';

final loadMemItems = FutureProvider.autoDispose.family<List<MemItem>, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final memItems = await MemService().fetchMemItemsByMemId(memId);

        if (memItems.isNotEmpty) {
          ref.watch(memItemsProvider(memId).notifier).updatedBy(memItems);
        }

        return memItems;
      }

      return [];
    },
    memId,
  ),
);
final loadMemNotifications = FutureProvider.autoDispose.family<void, int?>(
  (ref, memId) => v(
    () async {
      if (memId != null) {
        final memNotifications =
            await MemNotificationRepository().shipByMemId(memId);

        if (memNotifications.isNotEmpty) {
          ref
              .watch(memNotificationsProvider(memId).notifier)
              .updatedBy(memNotifications.toList());
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

            ref.read(editingMemProvider(memId).notifier).updatedBy(saved.mem);
            ref
                .read(memItemsProvider(memId).notifier)
                .updatedBy(saved.memItems);
            ref
                .read(memNotificationsProvider(memId).notifier)
                .updatedBy(saved.notifications);

            ref
                .read(rawMemListProvider.notifier)
                .upsertAll([saved.mem], (tmp, item) => tmp.id == item.id);

            return saved;
          },
          memId,
        ));

final archiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(memDetailProvider(memId)).mem;

      final archived = await MemService().archive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(archived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([archived.mem], (tmp, item) => tmp.id == item.id);

      return archived;
    },
    {'memId': memId},
  ),
);

final unarchiveMem = Provider.autoDispose.family<Future<MemDetail?>, int?>(
  (ref, memId) => v(
    () async {
      final mem = ref.read(memDetailProvider(memId)).mem;

      final unarchived = await MemService().unarchive(mem);

      ref.read(editingMemProvider(memId).notifier).updatedBy(unarchived.mem);
      ref
          .read(rawMemListProvider.notifier)
          .upsertAll([unarchived.mem], (tmp, item) => tmp.id == item.id);

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

        ref.read(removedMemProvider(memId).notifier).updatedBy(
              ref
                  .read(memListProvider)
                  .firstWhere((element) => element.id == memId),
            );
        ref.read(removedMemItemsProvider(memId).notifier).updatedBy(
              ref.read(memItemsProvider(memId)),
            );

        ref
            .read(rawMemListProvider.notifier)
            .removeWhere((element) => element.id == memId);

        return removeSuccess;
      }

      return false;
    },
    memId,
  ),
);
