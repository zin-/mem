import 'package:mem/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/client.dart';
import 'preference/keys.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

@riverpod
class Preferences extends _$Preferences {
  final _client = PreferenceClientRepository();

  @override
  Future<Map<PreferenceKey, dynamic>> build() => v(
        () async => {
          startOfDayKey: await _client.shipByKey(startOfDayKey).then(
                (v) => v.value,
              ),
          notifyAfterInactivity:
              await _client.shipByKey(notifyAfterInactivity).then(
                    (v) => v.value,
                  )
        },
      );

  Future<void> replace(PreferenceKey key, Object? value) => v(
        () async {
          if (value == null) {
            await _client.discard(key);
          } else {
            await _client.receive(PreferenceEntity(key, value));
          }

          state = AsyncData(state.value!..update(key, (v) => value));
        },
        {
          'key': key,
          'value': value,
        },
      );
}
