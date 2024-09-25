import 'dart:core';

import 'package:mem/logger/log_service.dart';

import '../framework/date_and_time/date_and_time_period.dart';

class Act {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);

  bool get isActive => period.start != null && period.end == null;

  static int activeCompare(Act? a, Act? b) => v(
        () {
          final aIsActive = a?.isActive;
          final bIsActive = b?.isActive;

          if ((aIsActive == null && bIsActive == null) ||
              (aIsActive == false && bIsActive == false) ||
              (aIsActive == null && bIsActive == false) ||
              (aIsActive == false && bIsActive == null)) {
            return 0;
          } else if (aIsActive == true && bIsActive == true) {
            return b!.period.start!.compareTo(a!.period.start as DateTime);
          } else {
            return (aIsActive == null || aIsActive == false) ? 1 : -1;
          }
        },
        {'a': a, 'b': b},
      );
}
