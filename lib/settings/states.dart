import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/actions.dart';
import 'package:mem/settings/keys.dart';

final startOfDayProvider = StateNotifierProvider.autoDispose<
    ValueStateNotifier<TimeOfDay?>, TimeOfDay?>(
  (ref) => d(
    () => ValueStateNotifier(
      null,
      future: loadByKey(startOfDayKey),
    ),
  ),
);
