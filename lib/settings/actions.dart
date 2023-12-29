import 'package:mem/logger/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> save(String key, Object? value) => v(
      () async {
        final sharedPreferences = await SharedPreferences.getInstance();

        switch (value.runtimeType) {
          case String:
            return await sharedPreferences.setString(key, value as String);

          default:
            throw UnimplementedError();
        }
      },
      {"key": key, "value": value},
    );

Future<Object?> loadByKey(String key) => v(
      () async {
        final sharedPreferences = await SharedPreferences.getInstance();

        return sharedPreferences.get(key);
      },
      {"key": key},
    );

Future<bool> remove(String key) => v(
      () async {
        final sharedPreferences = await SharedPreferences.getInstance();

        return sharedPreferences.remove(key);
      },
      {"key": key},
    );
