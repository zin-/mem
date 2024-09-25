import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/actions.dart';
import 'package:mem/settings/keys.dart';
import 'package:mem/values/constants.dart';

final startOfDayProvider =
    StateNotifierProvider<ValueStateNotifier<TimeOfDay>, TimeOfDay>(
  (ref) => v(
    () => ValueStateNotifier(
      defaultStartOfDay,
      initializer: (current, notifier) => v(
        () async => notifier
            .updatedBy(await loadByKey(startOfDayKey) ?? defaultStartOfDay),
        {
          'current': current,
          'notifier': notifier,
        },
      ),
    ),
  ),
);
