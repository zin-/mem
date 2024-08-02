import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

final doneMem = Provider.autoDispose.family<SavedMemV1, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memByMemIdProvider(memId))!
          .copiedWith(doneAt: () => DateTime.now());

      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [doneMemDetail.mem],
              (tmp, item) => tmp is SavedMemV1 && item is SavedMemV1
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem;
    },
    memId,
  ),
);

final undoneMem = Provider.autoDispose.family<SavedMemV1, int>(
  (ref, memId) => v(
    () {
      final mem =
          ref.read(memByMemIdProvider(memId))!.copiedWith(doneAt: () => null);

      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [undoneMemDetail.mem],
              (tmp, item) => tmp is SavedMemV1 && item is SavedMemV1
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem;
    },
    memId,
  ),
);
