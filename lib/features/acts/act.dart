import 'dart:core';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

enum ActKind {
  finished,
  skipped,
}

ActKind? actKindFromStored(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) return null;
  switch (raw) {
    case 'finished':
      return ActKind.finished;
    case 'skipped':
      return ActKind.skipped;
    default:
      return null;
  }
}

enum ActState {
  active,
  paused,
  finished,
}

abstract class Act {
  final int memId;
  final DateAndTimePeriod? period;
  final DateTime? pausedAt;
  final ActState state;
  final ActKind? actKind;

  Act(this.memId, this.period, this.pausedAt, this.state, this.actKind);

  factory Act.by(
    int memId, {
    DateAndTime? startWhen,
    DateAndTime? endWhen,
    DateTime? pausedAt,
    ActKind? completionKind,
    bool completionKindFromRow = false,
  }) {
    ActKind? resolvedCompletionKind() {
      if (!completionKindFromRow) {
        return completionKind ?? ActKind.finished;
      }
      return completionKind;
    }

    if (endWhen != null) {
      if (startWhen == null) {
        return FinishedAct(
          memId,
          endWhen,
          endWhen,
          actKind: resolvedCompletionKind(),
        );
      } else {
        return FinishedAct(
          memId,
          startWhen,
          endWhen,
          actKind: resolvedCompletionKind(),
        );
      }
    }
    if (startWhen != null) {
      return ActiveAct(memId, startWhen);
    }
    if (pausedAt != null) {
      return PausedAct(memId, pausedAt);
    }

    throw ArgumentError("引数が不足している。${{
      'startWhen': startWhen,
      'endWhen': endWhen,
      'pausedAt': pausedAt,
    }}");
  }

  bool get isActive => period?.start != null && period?.end == null;

  bool get isFinished => period?.start != null && period?.end != null;

  bool get isSkipped => actKind == ActKind.skipped;

  bool get isScheduleAnchor => isActive || isFinished;

  FinishedAct finish(DateAndTime when);

  ActiveAct start(DateAndTime when);
}

class ActiveAct extends Act {
  ActiveAct(int memId, DateAndTime startWhen)
      : super(
          memId,
          DateAndTimePeriod(start: startWhen),
          null,
          ActState.active,
          null,
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      FinishedAct(memId, period?.start ?? when, when, actKind: ActKind.finished);

  FinishedAct skip(DateAndTime when) =>
      FinishedAct(memId, period?.start ?? when, when, actKind: ActKind.skipped);

  @override
  ActiveAct start(DateAndTime when) =>
      throw StateError('This act has already been started.');
}

class FinishedAct extends Act {
  FinishedAct(
    int memId,
    DateAndTime startWhen,
    DateAndTime endWhen, {
    ActKind? actKind,
  }) : super(
          memId,
          DateAndTimePeriod(start: startWhen, end: endWhen),
          null,
          ActState.finished,
          actKind,
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      throw StateError('This act has already been finished.');

  @override
  ActiveAct start(DateAndTime when) =>
      throw StateError('This act has already been finished.');
}

class PausedAct extends Act {
  PausedAct(int memId, DateTime pausedAt)
      : super(
          memId,
          null,
          pausedAt,
          ActState.paused,
          null,
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      FinishedAct(memId, when, when, actKind: ActKind.finished);

  @override
  ActiveAct start(DateAndTime when) => ActiveAct(memId, when);
}
