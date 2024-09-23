import 'package:mem/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_entity.dart';

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

class ActRepository extends DatabaseTupleRepository<ActEntity, SavedActEntity> {
  ActRepository() : super(databaseDefinition, defTableActs);

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
    bool? isActive,
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
              if (isActive != null) IsNull(defColActsEnd.name),
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
          'isActive': isActive,
          'condition': condition,
          'groupBy': groupBy,
          'actOrderBy': actOrderBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  @override
  Future<List<SavedActEntity>> waste({int? id, Condition? condition}) => v(
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
}
