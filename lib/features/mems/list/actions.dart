import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';

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

      ref.read(memEntitiesProvider.notifier).upsert(mems);

      for (var mem in mems) {
        ref.read(memItemsProvider.notifier).upsertAll(
              await MemItemRepositoryV2().ship(memId: mem.id),
              (current, updating) =>
                  current is SavedMemItemEntityV2 &&
                  updating is SavedMemItemEntityV2 &&
                  current.id == updating.id,
            );
      }

      return mems;
    },
  ),
);
