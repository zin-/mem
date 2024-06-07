import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';

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

class ActRepository extends DatabaseTupleRepository<Act, SavedAct, int> {
  @override
  Future<SavedAct?> findOneBy({
    int? memId,
    bool? latest,
    Condition? condition,
    List<OrderBy>? orderBy,
  }) =>
      v(
        () async => await super.findOneBy(
          condition: And([
            if (memId != null) Equals(defFkActsMemId.name, memId),
            if (condition != null) condition, // coverage:ignore-line
          ]),
          orderBy: [
            if (latest == true) ActOrderBy.descStart.toQuery,
            if (orderBy != null) ...orderBy, // coverage:ignore-line
          ],
        ),
        {
          "memId": memId,
          "latest": latest,
          "condition": condition,
          "orderBy": orderBy,
        },
      );

  @override
  Future<int> count({
    int? memId,
    Condition? condition,
  }) =>
      v(
        () => super.count(
          condition: And(
            [
              if (memId != null) Equals(defFkActsMemId.name, memId),
              if (condition != null) condition, // coverage:ignore-line
            ],
          ),
        ),
        {
          "memId": memId,
          "condition": condition,
        },
      );

  @override
  Future<List<SavedAct>> ship({
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
              if (memId != null) Equals(defFkActsMemId.name, memId),
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
          'actOrderBy': actOrderBy,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<List<SavedAct>> shipActive() => v(
        () async => await ship(condition: IsNull(defColActsEnd.name)),
      );

  Future<List<SavedAct>> shipActiveByMemId(
    int memId,
  ) =>
      v(
        () async => await ship(
          condition: And([
            Equals(defFkActsMemId.name, memId),
            IsNull(defColActsEnd.name),
          ]),
        ),
        {
          "memId": memId,
        },
      );

  @override
  SavedAct pack(Map<String, dynamic> tuple) => SavedAct(
        tuple[defFkActsMemId.name],
        DateAndTimePeriod(
          start: DateAndTime.from(
            tuple[defColActsStart.name],
            timeOfDay: tuple[defColActsStartIsAllDay.name]
                ? null
                : tuple[defColActsStart.name],
          ),
          end: tuple[defColActsEnd.name] == null
              ? null
              : DateAndTime.from(
                  tuple[defColActsEnd.name],
                  timeOfDay: tuple[defColActsEndIsAllDay.name]
                      ? null
                      : tuple[defColActsEnd.name],
                ),
        ),
      )..pack(tuple);

  @override
  Map<String, dynamic> unpack(Act entity) {
    final map = {
      defFkActsMemId.name: entity.memId,
      defColActsStart.name: entity.period.start,
      defColActsStartIsAllDay.name: entity.period.start?.isAllDay,
      defColActsEnd.name: entity.period.end,
      defColActsEndIsAllDay.name: entity.period.end?.isAllDay,
    };

    if (entity is SavedAct) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  ActRepository._() : super(defTableActs);

  static ActRepository? _instance;

  factory ActRepository() => v(
        () => _instance ??= ActRepository._(),
      );
}
