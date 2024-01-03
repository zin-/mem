import 'package:mem/logger/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceRepository extends _KeyWithValueRepository<Preference, String> {
  @override
  Future<bool> receive(Preference entity) => v(
        () async {
          final sharedPreferences = await SharedPreferences.getInstance();

          switch (entity.value.runtimeType) {
            case String:
              return await sharedPreferences.setString(
                entity.key,
                entity.value as String,
              );

            default:
              throw UnimplementedError();
          }
        },
        entity,
      );

  @override
  Future<Preference?> findByKey(String key) => v(
        () async {
          final sharedPreferences = await SharedPreferences.getInstance();

          return Preference(key, sharedPreferences.get(key));
        },
        key,
      );

  @override
  Future<bool> discard(String key) => v(
        () async {
          final sharedPreferences = await SharedPreferences.getInstance();

          return sharedPreferences.remove(key);
        },
        key,
      );

  PreferenceRepository._();

  static PreferenceRepository? _instance;

  factory PreferenceRepository() => _instance ??= PreferenceRepository._();
}

class Preference extends _KeyWithValue<String, Object?> {
  Preference(super.value, super.key);
}

abstract class _ExRepository<E extends _ExEntity> {}

abstract class _KeyWithValueRepository<E extends _KeyWithValue<Key, Object?>,
        Key> extends _ExRepository<E>
    with
        _Receiver<E, bool>,
        _FinderByKey<E, Key>,
        _DiscarderByKey<E, Key, bool> {}

abstract class _ExEntity {}

abstract class _KeyWithValue<Key, Value> extends _ExEntity {
  final Key key;
  final Value value;

  _KeyWithValue(this.key, this.value);

  Map<String, Object?> _toMap() => {
        "key": key,
        "value": value,
      };

  @override
  String toString() => _toMap().toString();
}

mixin _Receiver<E extends _ExEntity, Result> on _ExRepository<E> {
  Future<Result> receive(E entity);
}
mixin _FinderByKey<E extends _KeyWithValue<Key, dynamic>, Key>
    on _ExRepository<E> {
  Future<E?> findByKey(Key key);
}
mixin _DiscarderByKey<E extends _KeyWithValue<Key, dynamic>, Key, Result>
    on _ExRepository<E> {
  Future<Result> discard(Key key);
}
