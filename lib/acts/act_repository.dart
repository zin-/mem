import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';

class ActRepository
    extends DatabaseTupleRepository<ActV2, SavedActV2<int>, int> {
  Future<List<SavedActV2<int>>> shipByMemId(
    MemId memId, {
    DateAndTimePeriod? period,
  }) =>
      v(
        () async {
          if (period == null) {
            return await ship(Equals(defFkActsMemId.name, memId));
          } else {
            return await ship(And([
              Equals(defFkActsMemId.name, memId),
              GraterThanOrEqual(defColActsStart, period.start),
              LessThan(defColActsStart, period.end),
            ]));
          }
        },
        {'memId': memId, 'period': period},
      );

  Future<List<SavedActV2<int>>> shipActive() => v(
        () async => await ship(IsNull(defColActsEnd.name)),
      );

  @override
  SavedActV2<int> pack(Map<String, dynamic> tuple) => SavedActV2<int>(
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
  Map<String, dynamic> unpack(ActV2 entity) {
    final map = {
      defFkActsMemId.name: entity.memId,
      defColActsStart.name: entity.period.start,
      defColActsStartIsAllDay.name: entity.period.start?.isAllDay,
      defColActsEnd.name: entity.period.end,
      defColActsEndIsAllDay.name: entity.period.end?.isAllDay,
    };

    if (entity is SavedActV2) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  ActRepository._() : super(defTableActs);

  static ActRepository? _instance;

  factory ActRepository() => _instance ??= ActRepository._();
}
