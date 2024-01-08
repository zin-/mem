import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/preference_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceClient
    extends _KeyWithValueRepository<Preference, PreferenceKey> {
  Future<Preference<T>> shipByKey<T>(PreferenceKey<T> key) => v(
        () async {
          final saved = (await SharedPreferences.getInstance()).get(key.value);

          return Preference(
            key,
            key.deserialize(saved),
          );
        },
        key,
      );

  @override
  Future<bool> receive(Preference entity) => v(
        () async {
          final serialized = entity.key.serialize(entity.value);

          switch (serialized.runtimeType) {
            case String:
              return await (await SharedPreferences.getInstance()).setString(
                entity.key.value,
                serialized,
              );

            default:
              throw UnimplementedError();
          }
        },
        entity,
      );

  @override
  Future<bool> discard(PreferenceKey key) => v(
        () async => (await SharedPreferences.getInstance()).remove(key.value),
        key,
      );

  PreferenceClient._();

  static PreferenceClient? _instance;

  factory PreferenceClient() => _instance ??= PreferenceClient._();
}

abstract class _ExRepository<Entity extends ExEntity> {}

abstract class _KeyWithValueRepository<
        Entity extends KeyWithValue<Key, dynamic>,
        Key> extends _ExRepository<Entity>
    with _Receiver<Entity, bool>, _DiscarderByKey<Entity, Key, bool> {}

mixin _Receiver<Entity extends ExEntity, Result> on _ExRepository<Entity> {
  Future<Result> receive(Entity entity);
}
mixin _DiscarderByKey<Entity extends KeyWithValue<Key, dynamic>, Key, Result>
    on _ExRepository<Entity> {
  Future<Result> discard(Key key);
}
