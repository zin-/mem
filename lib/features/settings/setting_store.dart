import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setting_store.g.dart';

@riverpod
class SettingStore extends _$SettingStore {
  @override
  Map<PreferenceKey, dynamic> build() => v(
        () => <PreferenceKey, dynamic>{},
      );

  T serveOneBy<T>(PreferenceKey<T> key) => v(
        () {
          var current = state[key];

          PreferenceRepository().shipByKey(key).then((v) {
            state.addAll({key: v.value});
          });

          if (current == null) {
            state.addAll({key: defaultPreferences[key]});
          }

          return state[key] as T;
        },
        {'key': key},
      );

  SettingStore();
}
