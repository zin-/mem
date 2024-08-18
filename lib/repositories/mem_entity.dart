import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/repositories/mem.dart';

class MemEntity extends Mem with Entity {
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

  MemEntity.fromV1(MemV1 savedMem)
      : this.fromMap(
          MemEntity(
            savedMem.name,
            savedMem.doneAt,
            savedMem.period,
          ).toMap,
        );

// coverage:ignore-start
  @override
  Entity copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      MemEntity(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
// coverage:ignore-end
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
  // SavedMemEntity(super.name, super.doneAt, super.period);

  SavedMemEntity.fromMap(
    Map<String, dynamic> map,
  ) : super.fromMap(map) {
    withMap(map);
  }

  SavedMemEntity.fromV1(SavedMemV1 savedMem)
      : this.fromMap(
          MemEntity.fromV1(savedMem).toMap
            ..addAll(
              {
                defPkId.name: savedMem.id,
                defColCreatedAt.name: savedMem.createdAt,
                defColUpdatedAt.name: savedMem.updatedAt,
                defColArchivedAt.name: savedMem.archivedAt,
              },
            ),
        );

  SavedMemV1 toV1() => SavedMemV1(name, doneAt, period)
    ..id = id
    ..createdAt = createdAt
    ..updatedAt = updatedAt
    ..archivedAt = archivedAt;
}
