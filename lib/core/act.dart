import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'date_and_time/date_and_time_period.dart';

class Act extends Entity {
  final int memId;
  final DateAndTimePeriod period;

  Act(this.memId, this.period);
}

class SavedAct<I> extends Act with SavedDatabaseTupleMixin<I> {
  SavedAct(super.memId, super.period);

  SavedAct<I> copiedWith(DateAndTimePeriod Function()? period) => SavedAct(
        memId,
        period == null ? this.period : period(),
      )
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;
}
