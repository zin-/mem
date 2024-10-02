import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference/wrapper.dart';
import 'package:mem/settings/preference/preference.dart';
import 'package:mem/settings/preference/preference_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceClientRepository
    extends KeyWithValueRepository<PreferenceEntity, PreferenceKey> {
  final _sharedPreferencesWrapper = SharedPreferencesWrapper();

  Future<PreferenceEntity<T>> shipByKey<T>(PreferenceKey<T> key) => v(
        () async {
          final saved = await _sharedPreferencesWrapper.get(key.value);

          return PreferenceEntity(
            key,
            key.deserialize(saved),
          );
        },
        {'key': key},
      );

  @override
  Future<bool> receive(PreferenceEntity entity) => v(
        () async {
          final serialized = entity.key.serialize(entity.value);

          switch (serialized.runtimeType) {
            case const (String):
              return await (await SharedPreferences.getInstance()).setString(
                entity.key.value,
                serialized,
              );

            default:
              throw UnimplementedError(); // coverage:ignore-line
          }
        },
        {'entity': entity},
      );

  @override
  Future<void> discard(PreferenceKey key) => v(
        () async => (await SharedPreferences.getInstance()).remove(key.value),
        {'key': key},
      );
}
