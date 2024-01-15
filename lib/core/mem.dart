import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/entity.dart';

class Mem extends EntityV1 {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  Mem(this.name, this.doneAt, this.period);

  bool get isDone => doneAt != null;

  Mem copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      Mem(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      );
}
