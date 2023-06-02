import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service_v2.dart';

final actListProvider = StateNotifierProvider.family<
    ListValueStateNotifier<Act>, List<Act>?, MemId>(
  (ref, memId) => v(
    () {
      final actList = ListValueStateNotifier<Act>(null);

      fetchByMemIdIs(memId).then((value) => actList.updatedBy(value));

      return actList;
    },
  ),
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
