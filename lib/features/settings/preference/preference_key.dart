import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

abstract class PreferenceKey<T> {
  final String value;

  PreferenceKey(this.value);

  T? deserialize(serialized);

  serialize(T? deserialized);

  @override
  String toString() => value;
}

class IntPreferenceKey extends PreferenceKey<int> {
  IntPreferenceKey(super.value);

  @override
  int? deserialize(serialized) => serialized;

  @override
  int? serialize(int? deserialized) => deserialized;
}

class TimeOfDayPreferenceKey extends PreferenceKey<TimeOfDay> {
  TimeOfDayPreferenceKey(super.value);

  @override
  TimeOfDay? deserialize(serialized) => v(
        () {
          if (serialized == null) {
            return null;
          } else {
            final hourAndMinute =
                serialized.split(":").map((e) => int.parse(e)).toList();
            return TimeOfDay(
              hour: hourAndMinute[0],
              minute: hourAndMinute[1],
            );
          }
        },
        {"serialized": serialized},
      );

  @override
  String? serialize(TimeOfDay? deserialized) => v(
        () => deserialized == null
            ? null
            : "${deserialized.hour}:${deserialized.minute}",
        {"deserialized": deserialized},
      );
}
