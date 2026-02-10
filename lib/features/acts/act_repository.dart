import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/framework/singleton.dart';

enum ActOrderBy { descStart }

extension _ActOrderByExt on ActOrderBy {
  OrderBy get toQuery {
    switch (index) {
      case 0:
        return Descending(defColActsStart);

      default:
        throw Exception(); // coverage:ignore-line
    }
  }
}

// @Deprecated('ActRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class ActRepository extends DatabaseTupleRepository<ActEntityV1,
    SavedActEntityV1, Act, int, ActEntity> {
  @override
  SavedActEntityV1 pack(Map<String, dynamic> map) => SavedActEntityV1(map);

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
  Future<List<SavedActEntityV1>> ship({
    int? memId,
    Iterable<int>? memIdsIn,
    DateAndTimePeriod? period,
    bool? latestByMemIds,
    bool? paused,
    Condition? condition,
    GroupBy? groupBy,
    ActOrderBy? actOrderBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () => super.ship(
          condition: And(
            [
              if (memId != null) Equals(defFkActsMemId, memId),
              if (memIdsIn != null) In(defFkActsMemId.name, memIdsIn),
              if (period != null)
                GraterThanOrEqual(defColActsStart, period.start),
              if (period != null) LessThan(defColActsStart, period.end),
              if (paused != null) IsNotNull(defColActsPausedAt.name),
              if (condition != null) condition,
            ],
          ),
          groupBy: latestByMemIds == true
              ? GroupBy(
                  [defFkActsMemId],
                  extraColumns: [Max(defColActsStart)],
                )
              : null,
          orderBy: [
            if (actOrderBy != null) actOrderBy.toQuery,
            if (orderBy != null) ...orderBy, // coverage:ignore-line
          ],
          offset: offset,
          limit: limit,
        ),
        {
          'memId': memId,
          'memIds': memIdsIn,
          'period': period,
          'latestByMemIds': latestByMemIds,
          'paused': paused,
          'condition': condition,
          'groupBy': groupBy,
          'actOrderBy': actOrderBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  @override
  Future<List<SavedActEntityV1>> waste({int? id, Condition? condition}) => v(
        () => super.waste(
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

  ActRepository._() : super(databaseDefinition, defTableActs);
  factory ActRepository() => Singleton.of(() => ActRepository._());
}
