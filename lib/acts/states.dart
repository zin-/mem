import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final actsProvider = StateNotifierProvider<
    ListValueStateNotifier<SavedAct>, List<SavedAct>?>(
  (ref) => v(() => ListValueStateNotifier(null)),
);

final actListProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<Act>, List<Act>?, int?>(
  (ref, memId) => v(
    () => ListValueStateNotifier(
      ref
          .watch(actsProvider)
          ?.where((act) => memId == null || act.memId == memId)
          .toList()
          .sorted((a, b) => b.period.compareTo(a.period)),
    ),
    memId,
  ),
);
