import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/setting_store.dart';
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
        () => ref.watch(settingStoreProvider.notifier).serveOneBy(key),
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
