import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

abstract class PreferenceKey<T> {
  final String value;

  PreferenceKey(this.value);

  T deserialize(serialized);

  @override
  String toString() => value;
}

class TimeOfDayPreferenceKey extends PreferenceKey<TimeOfDay> {
  TimeOfDayPreferenceKey(super.value);

  @override
  TimeOfDay deserialize(serialized) => v(
        () {
          final hourAndMinute =
              serialized.split(":").map((e) => int.parse(e)).toList();
          return TimeOfDay(
            hour: hourAndMinute[0],
            minute: hourAndMinute[1],
          );
        },
        {"serialized": serialized},
      );
}

// TODO どこに定義するのが適切か検討する
extension TimeOfDayExtension on TimeOfDay {
  String serialize() => d(
        () => "$hour:$minute",
        toString(),
      );
}
