import 'dart:core';

import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/logger/log_service.dart';

import 'date_and_time/date_and_time_period.dart';

class Act extends EntityV1 {
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

  @override
  String toString() => "${super.toString()}: ${{
        "memId": memId,
        "period": period,
      }}";
}

class SavedAct extends Act with SavedDatabaseTupleMixin<int> {
  SavedAct(super.memId, super.period);

  SavedAct copiedWith(DateAndTimePeriod Function()? period) => SavedAct(
        memId,
        period == null ? this.period : period(),
      )
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;
}
