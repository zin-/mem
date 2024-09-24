import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

final dateViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);

final timeViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);
