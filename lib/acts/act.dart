import 'dart:core';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

class Act {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);

  bool get isActive => period.start != null && period.end == null;

  static int compare(
    Act? a,
    Act? b, {
    bool onlyActive = false,
  }) =>
      v(
        () {
          final aIsActive = a?.isActive ?? false;
          final bIsActive = b?.isActive ?? false;

          if (aIsActive == false && bIsActive == false) {
            if (onlyActive) {
              return 0;
            } else {
              if (a == null || b == null) {
                return a == null && b == null
                    ? 0
                    : a == null
                        ? -1
                        : 1;
              }

              return a.period.end!.compareTo(b.period.end!);
            }
          } else if (aIsActive == true && bIsActive == true) {
            return b!.period.start!.compareTo(a!.period.start as DateTime);
          } else {
            return aIsActive == false ? 1 : -1;
          }
        },
        {
          'a': a,
          'b': b,
          'onlyActive': onlyActive,
        },
      );
}

abstract class ActV2 {
  final int memId;
  final DateAndTimePeriod? period;

  ActV2(this.memId, this.period);

  factory ActV2.by(
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

  bool get isActive => period?.start != null && period?.end == null;

  bool get isFinished => period?.end != null;

  ActV2 finish(DateAndTime when);
}

class ActiveAct extends ActV2 {
  @override
  DateAndTimePeriod get period => super.period!;

  ActiveAct(int memId, DateAndTime startWhen)
      : super(
          memId,
          DateAndTimePeriod(start: startWhen),
        );

  @override
  FinishedAct finish(DateAndTime when) =>
      FinishedAct(memId, period.start!, when);
}

class FinishedAct extends ActV2 {
  @override
  DateAndTimePeriod get period => super.period!;

  FinishedAct(
    int memId,
    DateAndTime startWhen,
    DateAndTime endWhen,
  ) : super(
          memId,
          DateAndTimePeriod(start: startWhen, end: endWhen),
        );

  @override
  ActV2 finish(DateAndTime when) =>
      throw StateError('This act has already been finished.');
}
