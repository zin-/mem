import 'package:mem/framework/repository/key_with_value_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/preference_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceClient
    extends KeyWithValueRepository<Preference, PreferenceKey> {
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
            case const (String):
              return await (await SharedPreferences.getInstance()).setString(
                entity.key.value,
                serialized,
              );

            default:
              throw UnimplementedError(); // coverage:ignore-line
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
