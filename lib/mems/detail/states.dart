import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/gui/value_state_notifier.dart';

final initialMem = Mem(name: '');

final memProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem?>, Mem?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(null),
  ),
);

final editingMemProvider =
    StateNotifierProvider.family<ValueStateNotifier<Mem>, Mem, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ValueStateNotifier(
      ref.watch(memProvider(memId)) ?? initialMem.copied(),
    ),
  ),
);

final memItemsProvider = StateNotifierProvider.family<
    ListValueStateNotifier<MemItem>, List<MemItem>?, int?>(
  (ref, memId) => v(
    {'memId': memId},
    () => ListValueStateNotifier<MemItem>(null),
  ),
);
