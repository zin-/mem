import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<MemEntityV1,
    SavedMemEntityV1, Mem, int, MemEntity> {
  @override
  SavedMemEntityV1 pack(Map<String, dynamic> map) => SavedMemEntityV1(map);

  @override
  MemEntity packV2(dynamic tuple) => MemEntity(
        tuple.id,
        tuple.name,
        tuple.doneAt,
        tuple.notifyOn == null && tuple.endOn == null
            ? null
            : DateAndTimePeriod(
                start: tuple.notifyOn == null
                    ? null
                    : DateAndTime.from(
                        tuple.notifyOn,
                        timeOfDay: tuple.notifyAt == null
                            ? null
                            : DateAndTime.from(tuple.notifyAt),
                      ),
                end: tuple.endOn == null
                    ? null
                    : DateAndTime.from(
                        tuple.endOn,
                        timeOfDay: tuple.endAt == null
                            ? null
                            : DateAndTime.from(tuple.endAt),
                      ),
              ),
        tuple.createdAt,
        tuple.updatedAt,
        tuple.archivedAt,
      );

  @override
  Future<List<SavedMemEntityV1>> ship({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      super.ship(
        condition: And(
          [
            if (id != null) Equals(defPkId, id),
            if (archived != null)
              archived
                  ? IsNotNull(defColArchivedAt.name)
                  : IsNull(defColArchivedAt.name),
            if (done != null)
              done
                  ? IsNotNull(defColMemsDoneAt.name)
                  : IsNull(defColMemsDoneAt.name),
            if (condition != null) condition,
          ],
        ),
        groupBy: groupBy,
        orderBy: orderBy,
        offset: offset,
        limit: limit,
      );

  @override
  Future<List<MemEntity>> wasteV2({
    int? id,
    Condition? condition,
  }) =>
      super.wasteV2(
        condition: And(
          [
            if (id != null) Equals(defPkId, id),
// coverage:ignore-start
            if (condition != null) condition,
// coverage:ignore-end
          ],
        ),
      );

  static MemRepository? _instance;
  factory MemRepository({MemRepository? mock}) =>
      _instance ??= mock ?? MemRepository._();
  MemRepository._() : super(databaseDefinition, defTableMems);
}
