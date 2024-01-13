import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class SavedMem extends Mem with SavedDatabaseTupleMixin<int> {
  SavedMem(super.name, super.doneAt, super.period);

  @override
  SavedMem copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      SavedMem(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      )..copiedFrom(this);

  @override
  String toString() => "SavedMem: ${{
        "name": name,
        "doneAt": doneAt,
        "period": period,
      }}${unpack()}";
}
