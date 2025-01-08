import 'package:mem/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/repository.dart';
import 'preference/keys.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

@riverpod
class Preferences extends _$Preferences {
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
          if (value == null) {
            await _repository.discard(key);
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
