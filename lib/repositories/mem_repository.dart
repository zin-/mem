import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';

class MemRepository
    extends DatabaseTupleRepository<MemV2, SavedMemV2<int>, int> {
  Future<List<SavedMemV2<int>>> shipByCondition(bool? archived, bool? done) =>
      v(
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
  SavedMemV2<int> pack(Map<String, dynamic> tuple) {
    final startOn = tuple[defColMemsStartOn.name];
    final endOn = tuple[defColMemsEndOn.name];

    return SavedMemV2<int>(
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
  Map<String, dynamic> unpack(MemV2 entity) {
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

    if (entity is SavedMemV2) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemRepository._() : super(defTableMems);

  static MemRepository? _instance;

  factory MemRepository() => _instance ??= MemRepository._();
}
