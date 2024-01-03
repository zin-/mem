import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/repository.dart';

final _repository = PreferenceRepository();

Future<bool> save(PreferenceKey key, Object? value) => v(
      () async => await _repository.receive(
        Preference(
          key.value,
          value is TimeOfDay ? value.serialize() : value,
        ),
      ),
      {"key": key, "value": value},
    );

Future<Object?> loadByKey(PreferenceKey key) => v(
      () async {
        final preference = await _repository.findByKey(key.value);
        final value = preference?.value;
        if (key.type == TimeOfDay && value != null) {
          return Preference(
            key.value,
            TimeOfDayExtension.deserialize(value as String),
          ).value;
        } else {
          return preference?.value;
        }
      },
      {"key": key},
    );

Future<bool> remove(PreferenceKey key) => v(
      () async => await _repository.discard(key.value),
      {"key": key},
    );

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
