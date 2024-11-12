import 'dart:core';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

abstract class Act {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);

  factory Act.by(
    int memId,
    DateAndTime startWhen, {
    DateAndTime? endWhen,
  }) {
    if (endWhen == null) {
      return ActiveAct(memId, startWhen);
    } else {
      return FinishedAct(memId, startWhen, endWhen);
    }
  }

  bool get isActive => period.start != null && period.end == null;

  Act finish(DateAndTime when);
}

class ActiveAct extends Act {
  ActiveAct(int memId, DateAndTime startWhen)
      : super(
          memId,
          DateAndTimePeriod(start: startWhen),
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      FinishedAct(memId, period.start!, when);
}

class FinishedAct extends Act {
  FinishedAct(
    int memId,
    DateAndTime startWhen,
    DateAndTime endWhen,
  ) : super(
          memId,
          DateAndTimePeriod(start: startWhen, end: endWhen),
        );

  @override
  Act finish(DateAndTime when) =>
      throw StateError('This act has already been finished.');
}
