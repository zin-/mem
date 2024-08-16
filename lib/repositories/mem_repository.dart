import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository_v1.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/repositories/mem.dart';

class MemRepositoryV1
    extends DatabaseTupleRepositoryV1<MemV1, SavedMemV1, int> {
  @override
  Future<List<SavedMemV1>> ship({
    bool? archived,
    bool? done,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () => super.ship(
          condition: And([
            if (archived != null)
              archived
                  ? IsNotNull(defColArchivedAt.name)
                  : IsNull(defColArchivedAt.name),
            if (done != null)
              done
                  ? IsNotNull(defColMemsDoneAt.name)
                  : IsNull(defColMemsDoneAt.name),
            if (condition != null) condition, // coverage:ignore-line
          ]),
          orderBy: orderBy,
          offset: offset,
          limit: limit,
        ),
        {
          'archived': archived,
          'done': done,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  @override
  Future<SavedMemV1?> findOneBy({
    int? id,
    Condition? condition,
    List<OrderBy>? orderBy,
  }) =>
      v(
        () => super.findOneBy(
          condition: And([
            if (id != null) Equals(defPkId, id),
            if (condition != null) condition, // coverage:ignore-line
          ]),
          orderBy: orderBy,
        ),
        {
          "id": id,
          "condition": condition,
          "orderBy": orderBy,
        },
      );

  @override
  SavedMemV1 pack(Map<String, dynamic> tuple) {
    final startOn = tuple[defColMemsStartOn.name];
    final endOn = tuple[defColMemsEndOn.name];

    return SavedMemV1(
      tuple[defColMemsName.name],
      tuple[defColMemsDoneAt.name],
      startOn == null && endOn == null
          ? null
          : DateAndTimePeriod(
              start: startOn == null
                  ? null
                  : DateAndTime.from(startOn,
                      timeOfDay: tuple[defColMemsStartAt.name]),
              end: endOn == null
                  ? null
                  : DateAndTime.from(endOn,
                      timeOfDay: tuple[defColMemsEndAt.name]),
            ),
    )..pack(tuple);
  }

  @override
  Map<String, dynamic> unpack(MemV1 entity) {
    final map = {
      defColMemsName.name: entity.name,
      defColMemsDoneAt.name: entity.doneAt,
      defColMemsStartOn.name: entity.period?.start,
      defColMemsStartAt.name:
          entity.period?.start?.isAllDay == true ? null : entity.period?.start,
      defColMemsEndOn.name: entity.period?.end,
      defColMemsEndAt.name:
          entity.period?.end?.isAllDay == true ? null : entity.period?.end,
    };

    if (entity is SavedMemV1) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemRepositoryV1._() : super(defTableMems);

  static MemRepositoryV1? _instance;

  factory MemRepositoryV1() => v(
        () => _instance ??= MemRepositoryV1._(),
      );
}
