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
        () {
          ref.read(settingStoreProvider.notifier).serveOneBy(key);
          final settings = ref.watch(settingStoreProvider);
          return (settings[key] ?? defaultPreferences[key]) as T;
        },
        {"key": key},
      );

  Future<void> replace(T updating) => v(
        () async {
          ref.read(settingStoreProvider.notifier).put(key, updating);
          await PreferenceRepository().receive(PreferenceEntity(key, updating));
        },
        {
          "updating": updating,
        },
      );

  Future<void> remove() => v(
        () async {
          final defaultValue = defaultPreferences[key] as T;
          ref.read(settingStoreProvider.notifier).put(key, defaultValue);
          await PreferenceRepository().discard(key);
        },
        {"key": key},
      );
}
