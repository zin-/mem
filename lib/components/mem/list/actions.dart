import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/mems/states.dart';

final loadMemList = FutureProvider(
  (ref) => v(
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final mems = await v(
        () => MemRepository()
            .ship(
              archived: showNotArchived == showArchived ? null : showArchived,
              done: showNotDone == showDone ? null : showDone,
            )
            .then((value) => value.map((e) => e.toV1())),
        {
          'showNotArchived': showNotArchived,
          'showArchived': showArchived,
          'showNotDone': showNotDone,
          'showDone': showDone,
        },
      );

      ref.read(memsProvider.notifier).upsertAll(
            mems,
            (tmp, item) => tmp is SavedMemV1 && item is SavedMemV1
                ? tmp.id == item.id
                : false,
          );
      for (var mem in mems) {
        ref.read(memItemsProvider.notifier).upsertAll(
              await MemItemRepository()
                  .ship(memId: mem.id)
                  .then((v) => v.map((e) => e.toV1())),
              (current, updating) =>
                  current is SavedMemItem &&
                  updating is SavedMemItem &&
                  current.id == updating.id,
            );
      }
    },
  ),
);
