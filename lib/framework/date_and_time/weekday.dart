import 'package:flutter/material.dart';

const _englishShortWeekdays = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

String weekdayLabel(
  MaterialLocalizations localizations,
  Locale locale,
  int weekday,
) {
  final index = weekday % 7;
  if (locale.languageCode == 'en') {
    return _englishShortWeekdays[index];
  }
  return localizations.narrowWeekdays[index];
}

List<int> weekdaysInLocalizedOrder(MaterialLocalizations localizations) {
  final start = localizations.firstDayOfWeekIndex == 0
      ? DateTime.sunday
      : localizations.firstDayOfWeekIndex;
  return List.generate(7, (i) => (start + i - 1) % 7 + 1);
}
