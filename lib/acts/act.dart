import 'dart:core';

import 'package:mem/logger/log_service.dart';

import '../framework/date_and_time/date_and_time_period.dart';

class Act {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);

  bool get isActive => period.start != null && period.end == null;

  static int compare(Act? a, Act? b) => v(
        () {
          final aIsActive = a?.isActive ?? false;
          final bIsActive = b?.isActive ?? false;

          if (aIsActive == false && bIsActive == false) {
            if (a == null || b == null) {
              return a == null && b == null
                  ? 0
                  : a == null
                      ? -1
                      : 1;
            }

            return a.period.end!.compareTo(b.period.end!);
          } else if (aIsActive == true && bIsActive == true) {
            return b!.period.start!.compareTo(a!.period.start as DateTime);
          } else {
            return aIsActive == false ? 1 : -1;
          }
        },
        {
          'a': a,
          'b': b,
        },
      );
}
