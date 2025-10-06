import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mems_state.dart';

import 'states.dart';

final undoRemoveMem = FutureProvider.autoDispose.family<void, int>(
  (ref, memId) => v(
    () async {
      final removeUndone =
          await ref.read(memEntitiesProvider.notifier).undoRemove(memId);
      if (removeUndone != null) {
        ref.read(memItemsProvider.notifier).upsertAll(
              removeUndone.$2,
              (current, updating) =>
                  current is SavedMemItemEntity &&
                  updating is SavedMemItemEntity &&
                  current.id == updating.id,
            );
      }
    },
    memId,
  ),
);
