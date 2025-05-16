import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntity with EntityV2<Act> {
  ActEntity(Act value) {
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
  ActEntity updatedWith(Act Function(Act v) update) => ActEntity(update(value));
}

class SavedActEntity extends ActEntity with DatabaseTupleEntityV2<int, Act> {
  SavedActEntity(Map<String, dynamic> map)
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

    entityTableRelations[ActEntity] ??= defTableActs;
  }

  @override
  SavedActEntity updatedWith(Act Function(Act v) update) =>
      SavedActEntity(toMap..addAll(super.updatedWith(update).toMap));
}
