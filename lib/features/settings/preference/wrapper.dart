import 'package:shared_preferences/shared_preferences.dart';

import 'package:mem/logger/log_service.dart';

class SharedPreferencesWrapper {
  late final Future<SharedPreferences> _sharedPreferencesFuture = _initialize();

  Future<Object?> get(String key) => v(
        () async => await _sharedPreferencesFuture.then(
          (sharedPreferences) => sharedPreferences.get(key),
        ),
        {
          'key': key,
        },
      );

  Future<bool> set(String key, Object? value) => v(
        () async => await _sharedPreferencesFuture.then(
          (sharedPreferences) async {
            switch (value.runtimeType) {
              case const (String):
                return await sharedPreferences.setString(
                  key,
                  value as String,
                );

              case const (int):
                return await sharedPreferences.setInt(
                  key,
                  value as int,
                );

              default:
                throw UnimplementedError(); // coverage:ignore-line
            }
          },
        ),
        {
          'key': key,
          'value': value,
        },
      );

  Future<bool> remove(String key) => v(
        () async => await _sharedPreferencesFuture.then(
          (sharedPreferences) async => await sharedPreferences.remove(
            key,
          ),
        ),
        {
          'key': key,
        },
      );

  Future<SharedPreferences> _initialize() => v(
        () async => await SharedPreferences.getInstance(),
      );

  SharedPreferencesWrapper._();

  static SharedPreferencesWrapper? _instance;

  factory SharedPreferencesWrapper() => v(
        () => _instance ??= SharedPreferencesWrapper._(),
        {
          '_instance': _instance,
        },
      );
}
