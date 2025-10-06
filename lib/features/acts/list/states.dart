import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

final dateViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);

final timeViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);
