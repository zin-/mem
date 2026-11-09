import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

class CountReferenceAct {
  final Act act;

  CountReferenceAct._(this.act);

  static CountReferenceAct? of({
    required Act? latestAct,
    Act? scheduleAnchorAct,
  }) {
    final picked = _pick(latestAct, scheduleAnchorAct);
    if (picked?.period?.end == null) return null;
    return CountReferenceAct._(picked!);
  }

  static Act? _pick(Act? latestAct, Act? scheduleAnchorAct) {
    if (latestAct != null && latestAct.isFinished && !latestAct.isSkipped) {
      return latestAct;
    }
    final anchor = scheduleAnchorForNotifications(
      latestAct: latestAct,
      scheduleAnchorAct: scheduleAnchorAct,
    );
    if (anchor != null && anchor.isFinished && !anchor.isSkipped) {
      return anchor;
    }
    return null;
  }

  DateAndTime logicalDay(TimeOfDay startOfDay) =>
      act.period!.end!.logicalDay(startOfDay);

  bool isWithinWeek(DateTime startOfToday, TimeOfDay startOfDay) {
    final today = DateAndTime(
      startOfToday.year,
      startOfToday.month,
      startOfToday.day,
    );
    final days = logicalDay(startOfDay).calendarDaysUntil(today);
    return days >= 0 && days < DateTime.daysPerWeek;
  }

  DateAndTimePeriod? week(TimeOfDay startOfDay) {
    final day = logicalDay(startOfDay);
    return Period.aWeek.toPeriod(
      DateAndTime(
        day.year,
        day.month,
        day.day,
        startOfDay.hour,
        startOfDay.minute,
      ),
      startOfDay,
    );
  }
}
