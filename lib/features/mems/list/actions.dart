import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';

final loadMemList = FutureProvider(
  (ref) => v(
    () async {
      final mems = await ref.watch(memEntitiesProvider.notifier).loadMemList(
            ref.watch(showArchivedProvider),
            ref.watch(showNotArchivedProvider),
            ref.watch(showDoneProvider),
            ref.watch(showNotDoneProvider),
          );
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
