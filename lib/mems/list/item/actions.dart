import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/mems/mem_entity.dart';

final doneMem = Provider.autoDispose.family<SavedMemEntity, int>(
  (ref, memId) => v(
    () {
      MemService().doneByMemId(memId).then(
            (doneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [
                doneMemDetail.mem,
              ],
              (tmp, item) => tmp is SavedMemEntity && item is SavedMemEntity
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return ref
          .read(memByMemIdProvider(memId))!
          .copiedWith(doneAt: () => DateTime.now());
    },
    memId,
  ),
);

final undoneMem = Provider.autoDispose.family<SavedMemEntity, int>(
  (ref, memId) => v(
    () {
      MemService().undoneByMemId(memId).then(
            (undoneMemDetail) => ref.read(memsProvider.notifier).upsertAll(
              [
                undoneMemDetail.mem,
              ],
              (tmp, item) => tmp is SavedMemEntity && item is SavedMemEntity
                  ? tmp.id == item.id
                  : false,
            ),
          );

      return ref
          .read(memByMemIdProvider(memId))!
          .copiedWith(doneAt: () => null);
    },
    memId,
  ),
);
