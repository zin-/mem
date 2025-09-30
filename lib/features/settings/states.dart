import 'package:mem/features/logger/log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preference/repository.dart';
import 'constants.dart';
import 'preference/preference.dart';
import 'preference/preference_key.dart';

part 'states.g.dart';

@riverpod
class Preference<T> extends _$Preference<T> {
  @override
  T build(PreferenceKey<T> key) => v(
        () {
          PreferenceRepository().shipByKey(key).then((v) {
            if (v.value != null) {
              state = v.value as T;
            }
          });
          return defaultPreferences[key] as T;
        },
        {"key": key},
      );

  Future<void> replace(T updating) => v(
        () async {
          state = updating;
          await PreferenceRepository().receive(PreferenceEntity(key, updating));
        },
        {
          "updating": updating,
        },
      );

  Future<void> remove() => v(
        () async {
          state = defaultPreferences[key] as T;
          await PreferenceRepository().discard(key);
        },
        {"key": key},
      );
}
