import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';

final editingActProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedActEntity>, SavedActEntity, int>(
  (ref, actId) => v(
    () => ValueStateNotifier(
      ref.read(actsProvider).singleWhere((act) => act.id == actId),
    ),
    actId,
  ),
);
