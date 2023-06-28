import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/component/view/mem_list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/gui/value_state_notifier.dart';

final editingMemProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    () {
      final rawMemList = ref.read(rawMemListProvider);
      final memFromRawMemList =
          rawMemList?.singleWhereOrNull((element) => element.id == memId);

      return ValueStateNotifier(
        memFromRawMemList ?? Mem(name: ''),
      );
    },
    memId,
  ),
);

final memItemsProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<MemItem>, List<MemItem>?, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier<MemItem>(null),
    memId,
  ),
);
