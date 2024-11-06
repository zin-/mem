import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntity with EntityV2<Act>, CopyableV2 {
  ActEntity(Act value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkActsMemId.name: value.memId,
        defColActsStart.name: value.period.start,
        defColActsStartIsAllDay.name: value.period.start?.isAllDay,
        defColActsEnd.name: value.period.end,
        defColActsEndIsAllDay.name: value.period.end?.isAllDay,
      };

  @override
  EntityV2<Act> copiedWith({
    int Function()? memId,
    DateAndTime Function()? start,
    DateAndTime? Function()? end,
  }) =>
      ActEntity(
        Act.by(
          memId == null ? value.memId : memId(),
          start == null ? value.period.start! : start(),
          endWhen: end == null ? value.period.end : end(),
        ),
      );
}

class SavedActEntity extends ActEntity with DatabaseTupleEntityV2<int, Act> {
  SavedActEntity(Map<String, dynamic> map)
      : super(
          Act.by(
            map[defFkActsMemId.name],
            DateAndTime.from(
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
          ),
        ) {
    withMap(map);
  }

  @override
  SavedActEntity copiedWith({
    int Function()? memId,
    DateAndTime Function()? start,
    DateAndTime? Function()? end,
  }) =>
      SavedActEntity(
        toMap
          ..addAll(
            super
                .copiedWith(
                  memId: memId,
                  start: start,
                  end: end,
                )
                .toMap,
          ),
      );
}
