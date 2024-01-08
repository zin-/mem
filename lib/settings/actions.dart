import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/entity.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/key.dart';

final _client = PreferenceClient();

Future<T?> loadByKey<T>(PreferenceKey<T> key) => v(
      () async => (await _client.findByKey(key))?.value,
      {"key": key},
    );

// TODO PreferenceKeyに返却型の情報を持たせて、repositoryもその型を受け取るようにする
Future<bool> save(PreferenceKey key, Object? value) => v(
      () async => await _client.receive(
        Preference(
          key,
          value is TimeOfDay ? value.serialize() : value,
        ),
      ),
      {"key": key, "value": value},
    );

Future<bool> remove(PreferenceKey key) => v(
      () async => await _client.discard(key),
      {"key": key},
    );
