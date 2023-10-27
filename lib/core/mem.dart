import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class MemV2 extends Entity {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  MemV2(this.name, this.doneAt, this.period);

  bool get isDone => doneAt != null;

  MemV2 copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      MemV2(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      );
}

class SavedMemV2<I> extends MemV2 with SavedDatabaseTupleMixin<I> {
  SavedMemV2(super.name, super.doneAt, super.period);

  @override
  SavedMemV2 copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      SavedMemV2<I>(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      )..copiedFrom(this);
}
