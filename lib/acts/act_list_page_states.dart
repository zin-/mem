import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

final actListProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<Act>, List<Act>?, MemId>(
  (ref, memId) => v(() => ListValueStateNotifier([])),
);

final editingActProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<Act>, Act, ActIdentifier>(
  (ref, actId) => v(
    () => ValueStateNotifier(
      ref
          .read(actListProvider(actId.memId))!
          .singleWhere((element) => element.id == actId.id),
    ),
    actId,
  ),
);
