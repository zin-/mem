import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

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
