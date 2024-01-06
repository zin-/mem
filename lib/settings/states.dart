import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

final startOfDayProvider =
    StateNotifierProvider<ValueStateNotifier<TimeOfDay?>, TimeOfDay?>(
  (ref) => v(
    () => ValueStateNotifier(null),
  ),
);
