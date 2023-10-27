import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';

final doneMem = Provider.autoDispose.family<SavedMem, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memsProvider)!
          .singleWhere((mem) => mem is SavedMem ? mem.id == memId : false)
          .copiedWith(doneAt: () => DateTime.now()) as SavedMem;

      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [doneMemDetail.mem],
              (tmp, item) => tmp is SavedMem && item is SavedMem
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem;
    },
    memId,
  ),
);

final undoneMem = Provider.autoDispose.family<SavedMem, int>(
  (ref, memId) => v(
    () {
      final mem = ref
          .read(memsProvider)!
          .singleWhere((mem) => mem is SavedMem ? mem.id == memId : false)
          .copiedWith(doneAt: () => null) as SavedMem;

      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [undoneMemDetail.mem],
              (tmp, item) => tmp is SavedMem && item is SavedMem
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return mem;
    },
    memId,
  ),
);
