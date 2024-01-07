import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceClient
    extends _KeyWithValueRepository<Preference, PreferenceKey> {
  @override
  Future<bool> receive(Preference entity) => v(
        () async {
          switch (entity.value.runtimeType) {
            case String:
              return await (await SharedPreferences.getInstance()).setString(
                entity.key.value,
                entity.value as String,
              );

            default:
              throw UnimplementedError();
          }
        },
        entity,
      );

  @override
  Future<Preference?> findByKey(PreferenceKey key) => v(
        () async => Preference(
          key,
          (await SharedPreferences.getInstance()).get(key.value),
        ),
        key,
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

abstract class _ExRepository<E extends ExEntity> {}

abstract class _KeyWithValueRepository<E extends KeyWithValue<Key, Object?>,
        Key> extends _ExRepository<E>
    with
        _Receiver<E, bool>,
        _FinderByKey<E, Key>,
        _DiscarderByKey<E, Key, bool> {}

mixin _Receiver<E extends ExEntity, Result> on _ExRepository<E> {
  Future<Result> receive(E entity);
}
mixin _FinderByKey<E extends KeyWithValue<Key, dynamic>, Key>
    on _ExRepository<E> {
  Future<E?> findByKey(Key key);
}
mixin _DiscarderByKey<E extends KeyWithValue<Key, dynamic>, Key, Result>
    on _ExRepository<E> {
  Future<Result> discard(Key key);
}
