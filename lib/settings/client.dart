import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/entity.dart';
import 'package:mem/settings/key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceClient extends _KeyWithValueRepository<Preference<dynamic>,
    PreferenceKey<dynamic>> {
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

  Future<Preference<T>> shipByKey<T>(PreferenceKey<T> key) => v(
        () async {
          final value = (await SharedPreferences.getInstance()).get(key.value);

          return Preference(
            key,
            value == null ? null : key.deserialize(value),
          );
        },
        key,
      );

  @override
  Future<bool> discard(PreferenceKey<dynamic> key) => v(
        () async => (await SharedPreferences.getInstance()).remove(key.value),
        key,
      );

  PreferenceClient._();

  static PreferenceClient? _instance;

  factory PreferenceClient() => _instance ??= PreferenceClient._();
}

abstract class _ExRepository<E extends ExEntity> {}

abstract class _KeyWithValueRepository<E extends KeyWithValue<Key, dynamic>,
        Key> extends _ExRepository<E>
    with _Receiver<E, bool>, _DiscarderByKey<E, Key, bool> {}

mixin _Receiver<E extends ExEntity, Result> on _ExRepository<E> {
  Future<Result> receive(E entity);
}
mixin _DiscarderByKey<E extends KeyWithValue<Key, dynamic>, Key, Result>
    on _ExRepository<E> {
  Future<Result> discard(Key key);
}
