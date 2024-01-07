import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/entity.dart';
import 'package:mem/settings/client.dart';

final _client = PreferenceClient();

// TODO PreferenceKeyに返却型の情報を持たせて、repositoryもその型を返却するようにする
Future<Object?> loadByKey(PreferenceKey key) => v(
      () async {
        final preference = await _client.findByKey(key);
        final value = preference?.value;
        if (key.type == TimeOfDay && value != null) {
          return Preference(
            key,
            TimeOfDayExtension.deserialize(value as String),
          ).value;
        } else {
          return preference?.value;
        }
      },
      {"key": key},
    );

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

// TODO どこに定義するのが適切か検討する
extension TimeOfDayExtension on TimeOfDay {
  static deserialize(String text) => v(
        () {
          final hourAndMinute =
              text.split(":").map((e) => int.parse(e)).toList();
          return TimeOfDay(
            hour: hourAndMinute[0],
            minute: hourAndMinute[1],
          );
        },
        {"text": text},
      );

  String serialize() => v(
        () => "$hour:$minute",
        toString(),
      );
}
