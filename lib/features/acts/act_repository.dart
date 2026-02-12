import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/framework/repository/dummy.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('ActRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class ActRepository extends DatabaseTupleRepository<ActEntityV1,
    SavedDummyEntity, Act, int, ActEntity> {
  @override
  pack(Map<String, dynamic> map) => throw UnimplementedError();

  @override
  ActEntity packV2(dynamic tuple) => ActEntity(
        tuple.memId,
        tuple.start == null
            ? null
            : DateAndTime.from(
                tuple.start,
                timeOfDay: tuple.startIsAllDay == true ? null : tuple.start,
              ),
        tuple.end == null
            ? null
            : DateAndTime.from(
                tuple.end,
                timeOfDay: tuple.endIsAllDay == true ? null : tuple.end,
              ),
        tuple.pausedAt,
        tuple.id,
        tuple.createdAt,
        tuple.updatedAt,
        tuple.archivedAt,
      );

  @override
  Future<List<ActEntity>> wasteV2({int? id, Condition? condition}) => v(
        () => super.wasteV2(
          condition: And(
            [
              if (id != null) Equals(defPkId, id),
              if (condition != null) condition, // coverage:ignore-line
            ],
          ),
        ),
        {
          'id': id,
          'condition': condition,
        },
      );

  Future<List<ActEntity>> wastePausedAct(int memId) => v(
        () async => await super.wasteV2(
          condition: And(
            [
              Equals(defFkActsMemId, memId),
              IsNotNull(defColActsPausedAt.name),
            ],
          ),
        ),
        {'memId': memId},
      );

  ActRepository._() : super(databaseDefinition, defTableActs);
  factory ActRepository() => Singleton.of(() => ActRepository._());
}
