import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

final dateViewProvider =
    StateNotifierProvider<ValueStateNotifier<Period>, Period>(
  (ref) => ValueStateNotifier(Period.aDay),
);

final timeViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);
