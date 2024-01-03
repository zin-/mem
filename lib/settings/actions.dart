import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/repository.dart';

final _repository = PreferenceRepository();

Future<bool> save(String key, Object? value) => v(
      () async => await _repository.receive(Preference(key, value)),
      {"key": key, "value": value},
    );

Future<Object?> loadByKey(String key) => v(
      () async => (await _repository.findByKey(key))?.value,
      {"key": key},
    );

Future<bool> remove(String key) => v(
      () async => await _repository.discard(key),
      {"key": key},
    );
