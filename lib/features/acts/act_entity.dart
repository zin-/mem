import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntityV1 with EntityV1<Act> {
  ActEntityV1(Act value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkActsMemId.name: value.memId,
        defColActsStart.name: value.period?.start,
        defColActsStartIsAllDay.name: value.period?.start?.isAllDay,
        defColActsEnd.name: value.period?.end,
        defColActsEndIsAllDay.name: value.period?.end?.isAllDay,
        defColActsPausedAt.name: value.pausedAt,
      };

  @override
  ActEntityV1 updatedWith(Act Function(Act v) update) =>
      ActEntityV1(update(value));
}

class SavedActEntityV1 extends ActEntityV1
    with DatabaseTupleEntityV1<int, Act> {
  SavedActEntityV1(Map<String, dynamic> map)
      : super(
          Act.by(
            map[defFkActsMemId.name],
            startWhen: map[defColActsStart.name] == null
                ? null
                : DateAndTime.from(
                    map[defColActsStart.name],
                    timeOfDay: map[defColActsStartIsAllDay.name]
                        ? null
                        : map[defColActsStart.name],
                  ),
            endWhen: map[defColActsEnd.name] == null
                ? null
                : DateAndTime.from(
                    map[defColActsEnd.name],
                    timeOfDay: map[defColActsEndIsAllDay.name]
                        ? null
                        : map[defColActsEnd.name],
                  ),
            pausedAt: map[defColActsPausedAt.name],
          ),
        ) {
    withMap(map);
  }

  @override
  SavedActEntityV1 updatedWith(Act Function(Act v) update) =>
      SavedActEntityV1(toMap..addAll(super.updatedWith(update).toMap));
}
