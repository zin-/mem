import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/mems/mem_entity.dart';

final doneMem = Provider.autoDispose.family<SavedMemEntityV2, int>(
  (ref, memId) => v(
    () {
      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [doneMemDetail.mem],
              (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return ref.read(memByMemIdProvider(memId))!.updatedWith(
            (mem) => mem.done(DateTime.now()),
          );
    },
    {
      'memId': memId,
    },
  ),
);

final undoneMem = Provider.autoDispose.family<SavedMemEntityV2, int>(
  (ref, memId) => v(
    () {
      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [undoneMemDetail.mem],
              (tmp, item) => tmp is SavedMemEntityV2 && item is SavedMemEntityV2
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return ref.read(memByMemIdProvider(memId))!.updatedWith(
            (mem) => mem.undone(),
          );
    },
    {
      'memId': memId,
    },
  ),
);
