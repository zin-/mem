import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setting_store.g.dart';

@Riverpod(keepAlive: true)
class SettingStore extends _$SettingStore {
  final _loadingKeys = <PreferenceKey>{};

  @override
  Map<PreferenceKey, dynamic> build() => v(
        () => <PreferenceKey, dynamic>{},
      );

  T serveOneBy<T>(PreferenceKey<T> key) => v(
        () {
          _ensureLoaded(key);
          return (state[key] ?? defaultPreferences[key]) as T;
        },
        {'key': key},
      );

  void _ensureLoaded(PreferenceKey key) {
    if (state.containsKey(key) || _loadingKeys.contains(key)) {
      return;
    }
    _loadingKeys.add(key);
    PreferenceRepository().shipByKey(key).then((entity) {
      if (!_loadingKeys.remove(key)) {
        return;
      }
      final value = entity.value ?? defaultPreferences[key];
      state = {...state, key: value};
    });
  }

  void put<T>(PreferenceKey<T> key, T value) => v(
        () {
          _loadingKeys.remove(key);
          state = {...state, key: value};
        },
        {'key': key, 'value': value},
      );

  SettingStore();
}
