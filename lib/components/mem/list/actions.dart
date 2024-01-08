import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/logger/log_service.dart';
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

      ref.read(memsProvider.notifier).upsertAll(
            mems,
            (tmp, item) =>
                tmp is SavedMem && item is SavedMem ? tmp.id == item.id : false,
          );
    },
  ),
);
