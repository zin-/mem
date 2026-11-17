import 'package:material_ui/material_ui.dart';
import 'package:mem/features/settings/preference/keys.dart';

const defaultStartOfDay = TimeOfDay(hour: 0, minute: 0);
const defaultNotifyAfterInactivity = 3600;
const defaultHabitualMemsCount = 3;
const minHabitualMemsCount = 1;
const maxHabitualMemsCount = 9;
const defaultHabitualMemsTimeRadius = 1;
const minHabitualMemsTimeRadius = 1;
const maxHabitualMemsTimeRadius = 12;
const defaultHabitualMemsLookback = 28;
const minHabitualMemsLookback = 1;
const maxHabitualMemsLookback = 90;

final defaultPreferences = {
  startOfDayKey: defaultStartOfDay,
  notifyAfterInactivity: defaultNotifyAfterInactivity,
  habitualMemsCountKey: defaultHabitualMemsCount,
  habitualMemsTimeRadiusKey: defaultHabitualMemsTimeRadius,
  habitualMemsLookbackKey: defaultHabitualMemsLookback,
};
