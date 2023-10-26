import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';

final doneMem = Provider.autoDispose.family<Mem, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memsProvider)!
          .singleWhere((mem) => mem is SavedMemV2 ? mem.id == memId : false)
          .copiedWith(doneAt: () => DateTime.now());

      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [doneMemDetail.mem],
              (tmp, item) => tmp is SavedMemV2 && item is SavedMemV2
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem.toV1();
    },
    memId,
  ),
);

final undoneMem = Provider.autoDispose.family<Mem, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memsProvider)!
          .singleWhere((mem) => mem is SavedMemV2 ? mem.id == memId : false)
          .copiedWith(doneAt: () => null);

      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [undoneMemDetail.mem],
              (tmp, item) => tmp is SavedMemV2 && item is SavedMemV2
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem.toV1();
    },
    memId,
  ),
);
