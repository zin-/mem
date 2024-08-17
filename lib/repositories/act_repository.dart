import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/act_entity.dart';

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

class ActRepositoryV2
    extends DatabaseTupleRepository<ActEntity, SavedActEntity> {
  ActRepositoryV2() : super(databaseDefinition, defTableActs);

  @override
  SavedActEntity pack(Map<String, dynamic> map) => SavedActEntity.fromMap(map);

  @override
  Future<int> count({
    int? memId,
    Condition? condition,
  }) =>
      v(
        () => super.count(
          condition: And(
            [
              if (memId != null) Equals(defFkActsMemId, memId),
              if (condition != null) condition, // coverage:ignore-line
            ],
          ),
        ),
        {
          'memId': memId,
          'condition': condition,
        },
      );

  @override
  Future<List<SavedActEntity>> ship({
    int? memId,
    Iterable<int>? memIdsIn,
    DateAndTimePeriod? period,
    bool? latestByMemIds,
    ActOrderBy? actOrderBy,
    Condition? condition,
    GroupBy? groupBy,
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
          'actOrderBy': actOrderBy,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );
}
