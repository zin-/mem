import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
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
            .shipByCondition(
              showNotArchived == showArchived ? null : showArchived,
              showNotDone == showDone ? null : showDone,
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
            mems.map((e) => MemV2.fromV1(e)),
            (tmp, item) => tmp is SavedMemV2 && item is SavedMemV2
                ? tmp.id == item.id
                : false,
          );
    },
  ),
);
