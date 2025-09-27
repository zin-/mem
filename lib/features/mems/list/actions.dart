import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';
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

      ref.watch(memItemsProvider.notifier).upsertAll(
            await MemItemRepository()
                .ship(memIdsIn: mems.map((mem) => mem.id).toList()),
            (current, updating) =>
                current is SavedMemItemEntity &&
                updating is SavedMemItemEntity &&
                current.id == updating.id,
          );
      await ref.watch(actEntitiesProvider.notifier).fetchLatestByMemIds(
            mems.map((mem) => mem.id).toList(),
          );

      return mems;
    },
  ),
);
