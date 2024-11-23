import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference/client.dart';
import 'package:mem/settings/preference/preference.dart';
import 'package:mem/settings/preference/preference_key.dart';
import 'package:mem/values/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'actions.dart';
import 'preference/keys.dart';

part 'states.g.dart';

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

@riverpod
class Preferences extends _$Preferences {
  final _client = PreferenceClientRepository();

  @override
  Future<Map<PreferenceKey, dynamic>> build() => v(
        () async => {
          startOfDayKey: await _client.shipByKey(startOfDayKey).then(
                (v) => v.value,
              ),
        },
      );

  Future<void> replace(PreferenceKey key, Object? value) => v(
        () async {
          if (value != null) {
            await _client.receive(PreferenceEntity(key, value));
            state = AsyncData(state.value!..update(key, (v) => value));
          }
        },
        {
          'key': key,
          'value': value,
        },
      );
}
