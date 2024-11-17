import 'dart:core';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

enum ActState {
  active,
  paused,
  finished,
}

abstract class Act {
  final int memId;
  final DateAndTimePeriod? period;
  final ActState state;

  Act(this.memId, this.period, this.state);

  factory Act.by(
    int memId,
    DateAndTime? startWhen, {
    DateAndTime? endWhen,
  }) {
    if (startWhen == null) {
      return PausedAct(memId);
    } else if (endWhen == null) {
      return ActiveAct(memId, startWhen);
    } else {
      return FinishedAct(memId, startWhen, endWhen);
    }
  }

  bool get isActive => period?.start != null && period?.end == null;

  bool get isFinished => period?.start != null && period?.end != null;

  FinishedAct finish(DateAndTime when);

  ActiveAct start(DateAndTime when);
}

class ActiveAct extends Act {
  ActiveAct(int memId, DateAndTime startWhen)
      : super(
          memId,
          DateAndTimePeriod(start: startWhen),
          ActState.active,
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      FinishedAct(memId, period?.start ?? when, when);

  @override
  ActiveAct start(DateAndTime when) =>
      throw StateError('This act has already been started.');
}

class FinishedAct extends Act {
  FinishedAct(
    int memId,
    DateAndTime startWhen,
    DateAndTime endWhen,
  ) : super(
          memId,
          DateAndTimePeriod(start: startWhen, end: endWhen),
          ActState.finished,
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      throw StateError('This act has already been finished.');

  @override
  ActiveAct start(DateAndTime when) =>
      throw StateError('This act has already been finished.');
}

class PausedAct extends Act {
  PausedAct(int memId)
      : super(
          memId,
          null,
          ActState.paused,
        );

  @override
  FinishedAct finish(DateAndTime when) => FinishedAct(memId, when, when);

  @override
  ActiveAct start(DateAndTime when) => ActiveAct(memId, when);
}
