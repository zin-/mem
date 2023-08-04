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
            (doneMem) => ref.read(memsProvider.notifier).upsertAll(
              [doneMem.mem],
              (tmp, item) => tmp.id == item.id,
            ),
          );

      return mem;
    },
    memId,
  ),
);
final undoneMem = Provider.autoDispose.family<Future<Mem>, int>(
  (ref, memId) => v(
    () async {
      final undoneMemDetail = await MemService().undoneByMemId(memId);

      ref
          .read(memsProvider.notifier)
          .upsertAll([undoneMemDetail.mem], (tmp, item) => tmp.id == item.id);

      return undoneMemDetail.mem;
    },
    {'memId': memId},
  ),
);
