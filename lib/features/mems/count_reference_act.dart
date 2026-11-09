import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

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

  bool isWithinWeek(DateTime startOfToday, TimeOfDay startOfDay) {
    final end = act.period?.end;
    if (end == null) return false;
    final period = week(startOfToday, startOfDay);
    if (period == null) return false;
    return period.includesStart(end);
  }

  DateAndTimePeriod? week(DateTime startOfToday, TimeOfDay startOfDay) {
    return Period.aWeek.toPeriod(
      DateAndTime(
        startOfToday.year,
        startOfToday.month,
        startOfToday.day,
        startOfDay.hour,
        startOfDay.minute,
      ),
      startOfDay,
    );
  }
}
