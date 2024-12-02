import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';
import 'package:mem/mems/mem_repository.dart';
import 'package:mem/mems/states.dart';

final loadMemList = FutureProvider(
  (ref) => v(
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final mems = await v(
        () => MemRepositoryV2().ship(
          archived: showNotArchived == showArchived ? null : showArchived,
          done: showNotDone == showDone ? null : showDone,
        ),
        {
          'showNotArchived': showNotArchived,
          'showArchived': showArchived,
          'showNotDone': showNotDone,
          'showDone': showDone,
        },
      );

      ref.read(memsProvider.notifier).upsertAll(
            mems,
            (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
                ? tmp.id == item.id
                : false,
          );
      for (var mem in mems) {
        ref.read(memItemsProvider.notifier).upsertAll(
              await MemItemRepository().ship(memId: mem.id),
              (current, updating) =>
                  current is SavedMemItemEntity &&
                  updating is SavedMemItemEntity &&
                  current.id == updating.id,
            );
      }

      return mems;
    },
  ),
);
