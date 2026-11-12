import 'package:material_ui/material_ui.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

class TodayActCount {
  final Target target;
  final int value;

  TodayActCount._(this.target, this.value);

  static TodayActCount? of(Target? target, int value) {
    if (target == null || !target.acceptsSecondsAfterLastAct) {
      return null;
    }
    return TodayActCount._(target, value);
  }

  static DateAndTimePeriod period(DateTime now, TimeOfDay startOfDay) =>
      Period.aDay.toPeriod(
        DateAndTime.from(now, timeOfDay: now),
        startOfDay,
      )!;
}
