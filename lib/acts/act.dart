import 'dart:core';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

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
