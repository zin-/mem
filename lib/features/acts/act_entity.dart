import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem.dart';
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

  factory SavedActEntityV1.fromEntityV2(ActEntity entity) => SavedActEntityV1(
        {
          defFkActsMemId.name: entity.memId,
          defColActsStart.name: entity.start,
          defColActsStartIsAllDay.name: entity.start?.isAllDay,
          defColActsEnd.name: entity.end,
          defColActsEndIsAllDay.name: entity.end?.isAllDay,
          defColActsPausedAt.name: entity.pausedAt,
          defPkId.name: entity.id,
          defColCreatedAt.name: entity.createdAt,
          defColUpdatedAt.name: entity.updatedAt,
          defColArchivedAt.name: entity.archivedAt,
        },
      );

  ActEntity toEntityV2() => ActEntity(
        value.memId,
        value.period?.start,
        value.period?.end,
        value.pausedAt,
        id,
        createdAt,
        updatedAt,
        archivedAt,
      );
}

class ActEntity implements Entity<int> {
  final MemId memId;
  final DateAndTime? start;
  final DateAndTime? end;
  final DateTime? pausedAt;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  ActEntity(
    this.memId,
    this.start,
    this.end,
    this.pausedAt,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  Act toDomain() => Act.by(
        memId!,
        startWhen: start,
        endWhen: end,
        pausedAt: pausedAt,
      );

  factory ActEntity.fromTuple(dynamic tuple) => ActEntity(
        tuple[defFkActsMemId.name],
        tuple[defColActsStart.name] == null
            ? null
            : DateAndTime.from(
                tuple[defColActsStart.name],
                timeOfDay: tuple[defColActsStartIsAllDay.name] == true
                    ? null
                    : tuple[defColActsStart.name],
              ),
        tuple[defColActsEnd.name] == null
            ? null
            : DateAndTime.from(
                tuple[defColActsEnd.name],
                timeOfDay: tuple[defColActsEndIsAllDay.name] == true
                    ? null
                    : tuple[defColActsEnd.name],
              ),
        tuple[defColActsPausedAt.name],
        tuple[defPkId.name],
        tuple[defColCreatedAt.name],
        tuple[defColUpdatedAt.name],
        tuple[defColArchivedAt.name],
      );
}

convertIntoActsUpdateable(ActEntity entity, {DateTime? updatedAt}) =>
    drift_database.ActsCompanion(
      start: Value(entity.start),
      startIsAllDay: Value(entity.start?.isAllDay),
      end: Value(entity.end),
      endIsAllDay: Value(entity.end?.isAllDay),
      pausedAt: Value(entity.pausedAt),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
