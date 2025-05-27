import 'package:mem/features/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/client.dart';
import 'preference/repository.dart';
import 'preference/keys.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

@riverpod
class Preferences extends _$Preferences {
  final _client = PreferenceClient();
  final _repository = PreferenceRepository();

  @override
  Future<Map<PreferenceKey, dynamic>> build() => v(
        () async => {
          startOfDayKey: await _repository.shipByKey(startOfDayKey).then(
                (v) => v.value,
              ),
          notifyAfterInactivity:
              await _repository.shipByKey(notifyAfterInactivity).then(
                    (v) => v.value,
                  )
        },
      );

  Future<void> replace(PreferenceKey key, Object? value) => v(
        () async {
          if (key == notifyAfterInactivity) {
            await _client.updateNotifyAfterInactivity(value as int?);
          } else {
            await _repository.receive(PreferenceEntity(key, value));
          }

          state = AsyncData(state.value!..update(key, (v) => value));
        },
        {
          'key': key,
          'value': value,
        },
      );
}
