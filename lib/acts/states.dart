import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final actsProvider =
    StateNotifierProvider<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(() => ListValueStateNotifier(null)),
);

// FIXME loadActListと同じIFな気がする、統一できるのではないか？
final actListProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<Act>, List<Act>?, int?>(
  (ref, memId) => v(
    () {
      final acts = ref.watch(actsProvider);
      return ListValueStateNotifier(
        (memId == null
                ? acts
                : acts?.where((act) => act.memId == memId).toList())
            ?.sorted((a, b) => b.period.compareTo(a.period)),
      );
    },
    memId,
  ),
);
