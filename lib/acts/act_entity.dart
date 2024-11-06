import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntity extends Act with Entity, Copyable<ActEntity> {
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
  ActEntity copiedWith({
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

  @override
  Act finish(DateAndTime when) => throw StateError('実装する気はない');
}

class SavedActEntity extends ActEntity with DatabaseTupleEntity<int> {
  SavedActEntity(super.memId, super.period, Map<String, dynamic> map)
      : super() {
    withMap(map);
  }

  SavedActEntity.fromMap(Map<String, dynamic> map) : super.fromMap(map) {
    withMap(map);
  }

  @override
  SavedActEntity copiedWith({
    int Function()? memId,
    DateAndTimePeriod Function()? period,
  }) =>
      SavedActEntity.fromMap(
          toMap..addAll(super.copiedWith(memId: memId, period: period).toMap));
}

class ActEntityV2 with EntityV2<Act>, CopyableV2 {
  ActEntityV2(Act value) {
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
      ActEntityV2(
        Act.by(
          memId == null ? value.memId : memId(),
          start == null ? value.period.start! : start(),
          endWhen: end == null ? value.period.end : end(),
        ),
      );
}

class SavedActEntityV2 extends ActEntityV2
    with DatabaseTupleEntityV2<int, Act> {
  SavedActEntityV2(Map<String, dynamic> map)
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
  SavedActEntityV2 copiedWith({
    int Function()? memId,
    DateAndTime Function()? start,
    DateAndTime? Function()? end,
  }) =>
      SavedActEntityV2(
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

  SavedActEntity toV1() => SavedActEntity.fromMap(toMap);
}
