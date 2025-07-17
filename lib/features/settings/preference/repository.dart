import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/features/logger/log_service.dart';

import 'preference.dart';
import 'preference_key.dart';
import 'wrapper.dart';

class PreferenceRepository
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

  @override
  waste({Condition? condition}) {
    // TODO: implement waste
    throw UnimplementedError();
  }
}
