import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/entity.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/key.dart';

final _client = PreferenceClient();

Future<T?> loadByKey<T>(PreferenceKey<T> key) => v(
      () async => (await _client.shipByKey(key)).value,
      {"key": key},
    );

Future<bool> save<Key extends PreferenceKey<Value>, Value>(
  Key key,
  Value value,
) =>
    v(
      () async => await _client.receive(Preference(key, value)),
      {"key": key, "value": value},
    );

Future<bool> remove(PreferenceKey key) => v(
      () async => await _client.discard(key),
      {"key": key},
    );
