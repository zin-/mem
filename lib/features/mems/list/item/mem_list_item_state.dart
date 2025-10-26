import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mem_list_item_state.g.dart';

@riverpod
class MemListItem extends _$MemListItem {
  @override
  Mem build(MemId memId) {
    return ref
        .watch(memListProvider)
        .firstWhere((mem) => mem.id == memId)
        .value;
  }
}
