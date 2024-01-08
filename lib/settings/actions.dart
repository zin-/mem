import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/preference_key.dart';

final _client = PreferenceClient();

Future<T?> loadByKey<T>(PreferenceKey<T> key) => v(
      () async => (await _client.shipByKey(key)).value,
      {"key": key},
    );

Future<bool> update<Key extends PreferenceKey<Value>, Value>(
  Key key,
  Value? value,
) =>
    v(
      () async => await (value == null
          ? _client.discard(key)
          : _client.receive(Preference(key, value))),
      {"key": key, "value": value},
    );
