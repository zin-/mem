import 'package:mem/date_and_time/date_and_time.dart';
import 'package:mem/date_and_time/date_and_time_period.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemEntity extends Mem with Entity, Copyable<MemEntity> {
  MemEntity(super.name, super.doneAt, super.period);

  MemEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defColMemsName.name],
          map[defColMemsDoneAt.name],
          map[defColMemsStartOn.name] == null &&
                  map[defColMemsEndOn.name] == null
              ? null
              : DateAndTimePeriod(
                  start: map[defColMemsStartOn.name] == null
                      ? null
                      : DateAndTime.from(map[defColMemsStartOn.name],
                          timeOfDay: map[defColMemsStartAt.name]),
                  end: map[defColMemsEndOn.name] == null
                      ? null
                      : DateAndTime.from(map[defColMemsEndOn.name],
                          timeOfDay: map[defColMemsEndAt.name]),
                ),
        );

  @override
  MemEntity copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      MemEntity(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      );

  @override
  Map<String, dynamic> get toMap => {
        defColMemsName.name: name,
        defColMemsDoneAt.name: doneAt,
        defColMemsStartOn.name: period?.start,
        defColMemsStartAt.name:
            period?.start?.isAllDay == true ? null : period?.start,
        defColMemsEndOn.name: period?.end,
        defColMemsEndAt.name:
            period?.end?.isAllDay == true ? null : period?.end,
      };
}

class SavedMemEntity extends MemEntity with DatabaseTupleEntity<int> {
  SavedMemEntity(super.name, super.doneAt, super.period);

  SavedMemEntity.fromMap(
    Map<String, dynamic> map,
  ) : super.fromMap(map) {
    withMap(map);
  }

  @override
  SavedMemEntity copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      SavedMemEntity.fromMap(
        toMap
          ..addAll(
            super
                .copiedWith(
                  name: name,
                  doneAt: doneAt,
                  period: period,
                )
                .toMap,
          ),
      );
}
