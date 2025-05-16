import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/mems/mem_entity.dart';

final doneMem = Provider.autoDispose.family<SavedMemEntityV2, int>(
  (ref, memId) => v(
    () {
      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memEntitiesProvider.notifier).upsert(
              [doneMemDetail.mem as SavedMemEntityV2],
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
            (undoneMemDetail) => ref.read(memEntitiesProvider.notifier).upsert(
              [undoneMemDetail.mem as SavedMemEntityV2],
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
