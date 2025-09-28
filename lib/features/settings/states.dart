import 'package:mem/features/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/repository.dart';
import 'constants.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

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
