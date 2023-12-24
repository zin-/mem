import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';

class MemRepository extends DatabaseTupleRepository<Mem, SavedMem, int> {
  Future<List<SavedMem>> shipByCondition(bool? archived, bool? done) => v(
        () => super.ship(
          And([
            archived == null
                ? null
                : archived
                    ? IsNotNull(defColArchivedAt.name)
                    : IsNull(defColArchivedAt.name),
            done == null
                ? null
                : done
                    ? IsNotNull(defColMemsDoneAt.name)
                    : IsNull(defColMemsDoneAt.name),
          ].whereType<Condition>()),
        ),
        {
          'archived': archived,
          'done': done,
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

  factory MemRepository() => _instance ??= MemRepository._();
}
