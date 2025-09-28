import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/client.dart';
import 'preference/repository.dart';
import 'preference/keys.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

@riverpod
class Preferences extends _$Preferences {
  @override
  Future<Map<PreferenceKey, dynamic>> build() => v(
        () async => {
          startOfDayKey:
              await PreferenceRepository().shipByKey(startOfDayKey).then(
                    (v) => v.value,
                  ),
          notifyAfterInactivity: await PreferenceRepository()
              .shipByKey(notifyAfterInactivity)
              .then(
                (v) => v.value,
              )
        },
      );

  Future<void> replace(PreferenceKey key, Object? value) => v(
        () async {
          if (key == notifyAfterInactivity) {
            await PreferenceClient().updateNotifyAfterInactivity(value as int?);
          } else {
            await PreferenceRepository().receive(PreferenceEntity(key, value));
          }

          state = AsyncData(state.value!..update(key, (v) => value));
        },
        {
          'key': key,
          'value': value,
        },
      );
}

@riverpod
class Preference extends _$Preference {
  @override
  dynamic build(PreferenceKey key) => v(
        () {
          PreferenceRepository().shipByKey(key).then((v) {
            if (v.value != null) {
              state = v.value;
            }
          });
          return defaultPreferences[key];
        },
        {"key": key},
      );

  Future<void> replace(dynamic updating) => v(
        () async {
          state = updating;
          await PreferenceRepository().receive(PreferenceEntity(key, updating));
        },
        {
          "updating": updating,
        },
      );
}
