import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/services/mem_service.dart';
import 'package:mem/view/mems/mem_detail/mem_detail_states.dart';

final doneMem = Provider.autoDispose.family<Future<MemDetail>, int>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final doneMemDetail = await MemService().doneByMemId(memId);

      ref
          .read(memProvider(doneMemDetail.mem.id).notifier)
          .updatedBy(doneMemDetail.mem);

      return doneMemDetail;
    },
  ),
);
final undoneMem = Provider.autoDispose.family<Future<MemDetail>, int>(
  (ref, memId) => v(
    {'memId': memId},
    () async {
      final undoneMemDetail = await MemService().undoneByMemId(memId);

      ref
          .read(memProvider(undoneMemDetail.mem.id).notifier)
          .updatedBy(undoneMemDetail.mem);

      return undoneMemDetail;
    },
  ),
);
