import 'package:shared_preferences/shared_preferences.dart';

import 'package:mem/logger/log_service.dart';

class SharedPreferencesWrapper {
  late final Future<SharedPreferences> _sharedPreferencesFuture = _initialize();

  Future<Object?> get(String key) => v(
        () async => await _sharedPreferencesFuture.then(
          (value) {
            return value.get(key);
          },
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
