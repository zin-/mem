import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_repository_v2.dart';

final loadMemList = FutureProvider(
  (ref) => v(
    () async {
      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final mems = await v(
        () => MemRepository().shipByCondition(
          showNotArchived == showArchived ? null : showArchived,
          showNotDone == showDone ? null : showDone,
        ),
        {
          'showNotArchived': showNotArchived,
          'showArchived': showArchived,
          'showNotDone': showNotDone,
          'showDone': showDone,
        },
      );

      ref.read(rawMemListProvider.notifier).upsertAll(
            mems,
            (tmp, item) => tmp.id == item.id,
          );
    },
  ),
);
