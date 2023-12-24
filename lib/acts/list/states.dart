import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';

final dateViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);

final timeViewProvider = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(true),
);
