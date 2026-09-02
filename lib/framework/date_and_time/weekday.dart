import 'package:flutter/material.dart';

String weekdayLabel(MaterialLocalizations localizations, int weekday) =>
    localizations.narrowWeekdays[weekday % 7];

List<int> weekdaysInLocalizedOrder(MaterialLocalizations localizations) {
  final start = localizations.firstDayOfWeekIndex == 0
      ? DateTime.sunday
      : localizations.firstDayOfWeekIndex;
  return List.generate(7, (i) => (start + i - 1) % 7 + 1);
}
