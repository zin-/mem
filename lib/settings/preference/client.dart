import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference/wrapper.dart';
import 'package:mem/settings/preference/preference.dart';
import 'package:mem/settings/preference/preference_key.dart';

class PreferenceClientRepository
    extends KeyWithValueRepository<PreferenceEntity, PreferenceKey> {
  final _sharedPreferencesWrapper = SharedPreferencesWrapper();

  Future<PreferenceEntity<T>> shipByKey<T>(PreferenceKey<T> key) => v(
        () async => PreferenceEntity(
          key,
          key.deserialize(
            await _sharedPreferencesWrapper.get(
              key.value,
            ),
          ),
        ),
        {
          'key': key,
        },
      );

  @override
  Future<bool> receive(PreferenceEntity entity) => v(
        () async => await _sharedPreferencesWrapper.set(
          entity.key.value,
          entity.key.serialize(
            entity.value,
          ),
        ),
        {
          'entity': entity,
        },
      );

  @override
  Future<void> discard(PreferenceKey key) => v(
        () async => await _sharedPreferencesWrapper.remove(
          key.value,
        ),
        {
          'key': key,
        },
      );
}
