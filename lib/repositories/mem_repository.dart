import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/repositories/mem.dart';

class MemRepository extends DatabaseTupleRepository<Mem, SavedMem, int> {
  @override
  Future<List<SavedMem>> ship({
    bool? archived,
    bool? done,
    Condition? condition,
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
          "archived": archived,
          "done": done,
          "condition": condition,
          "orderBy": orderBy,
          "offset": offset,
          "limit": limit,
        },
      );

  @override
  SavedMem pack(Map<String, dynamic> tuple) {
    final startOn = tuple[defColMemsStartOn.name];
    final endOn = tuple[defColMemsEndOn.name];

    return SavedMem(
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
  Map<String, dynamic> unpack(Mem entity) {
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

    if (entity is SavedMem) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemRepository._() : super(defTableMems);

  static MemRepository? _instance;

  factory MemRepository() => v(
        () => _instance ??= MemRepository._(),
      );
}
