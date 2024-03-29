import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final editingActProvider = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<SavedAct>, SavedAct, int>(
  (ref, actId) => v(
    () => ValueStateNotifier(
      ref.read(actsProvider).singleWhere((act) => act.id == actId),
    ),
    actId,
  ),
);
