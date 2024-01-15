import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'date_and_time/date_and_time_period.dart';

class Act extends EntityV1 {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);

  Map<String, Object?> _toMap() => {
        "memId": memId,
        "period": period,
      };

  @override
  String toString() => _toMap().toString();
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

  @override
  Map<String, Object?> _toMap() => super._toMap()..addAll(unpack());
}
