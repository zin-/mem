import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class SavedMemV1 extends MemV1 with SavedDatabaseTupleMixinV1<int> {
  SavedMemV1(super.name, super.doneAt, super.period);

  @override
  SavedMemV1 copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      SavedMemV1(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      )..copiedFrom(this);
}
