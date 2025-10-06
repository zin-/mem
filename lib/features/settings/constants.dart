import 'package:flutter/material.dart';
import 'package:mem/features/settings/preference/keys.dart';

const defaultStartOfDay = TimeOfDay(hour: 0, minute: 0);
const defaultNotifyAfterInactivity = 3600;

final defaultPreferences = {
  startOfDayKey: defaultStartOfDay,
  notifyAfterInactivity: defaultNotifyAfterInactivity,
};
