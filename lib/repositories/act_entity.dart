import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntity extends ActV2 with Entity {
  ActEntity(super.memId, super.period);

  ActEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defFkActsMemId.name],
          DateAndTimePeriod(
            start: DateAndTime.from(
              map[defColActsStart.name],
              timeOfDay: map[defColActsStartIsAllDay.name]
                  ? null
                  : map[defColActsStart.name],
            ),
            end: map[defColActsEnd.name] == null
                ? null
                : DateAndTime.from(
                    map[defColActsEnd.name],
                    timeOfDay: map[defColActsEndIsAllDay.name]
                        ? null
                        : map[defColActsEnd.name],
                  ),
          ),
        );

  @override
  Entity copiedWith({
    int Function()? memId,
    DateAndTimePeriod Function()? period,
  }) =>
      ActEntity(
        memId == null ? this.memId : memId(),
        period == null ? this.period : period(),
      );

  @override
  Map<String, dynamic> get toMap => {
        defFkActsMemId.name: memId,
        defColActsStart.name: period.start,
        defColActsStartIsAllDay.name: period.start?.isAllDay,
        defColActsEnd.name: period.end,
        defColActsEndIsAllDay.name: period.end?.isAllDay,
      };
}

class SavedActEntity extends ActEntity with DatabaseTupleEntity<int> {
  SavedActEntity.fromMap(Map<String, dynamic> map) : super.fromMap(map) {
    withMap(map);
  }

  SavedActEntity.fromV1(SavedAct savedAct)
      : this.fromMap(ActEntity(savedAct.memId, savedAct.period).toMap
          ..addAll({
            defPkId.name: savedAct.id,
            defColCreatedAt.name: savedAct.createdAt,
            defColUpdatedAt.name: savedAct.updatedAt,
            defColArchivedAt.name: savedAct.archivedAt
          }));

  SavedAct toV1() => SavedAct(memId, period)
    ..id = id
    ..createdAt = createdAt
    ..updatedAt = updatedAt
    ..archivedAt = archivedAt;

  @override
  SavedActEntity copiedWith({
    int Function()? memId,
    DateAndTimePeriod Function()? period,
  }) =>
      SavedActEntity.fromMap(
          toMap..addAll(super.copiedWith(memId: memId, period: period).toMap));
}
