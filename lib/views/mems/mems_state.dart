import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/views/atoms/state_notifier.dart';

final initialized = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
    (ref) => ValueStateNotifier(false));