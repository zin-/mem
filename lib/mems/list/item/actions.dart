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
          .singleWhere((mem) => mem.id == memId)
          .copied()
        ..doneAt = DateTime.now();

      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [doneMemDetail.mem.toV1()],
              (tmp, item) => tmp.id == item.id,
            ),
          );

      return mem;
    },
    memId,
  ),
);

final undoneMem = Provider.autoDispose.family<Mem, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memsProvider)!
          .singleWhere((mem) => mem.id == memId)
          .copied()
        ..doneAt = null;

      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [undoneMemDetail.mem.toV1()],
              (tmp, item) => tmp.id == item.id,
            ),
          );

      return mem;
    },
    memId,
  ),
);
