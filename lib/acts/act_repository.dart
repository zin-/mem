import 'package:mem/acts/act_entity.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/i/_database_tuple_repository.dart';
import 'package:mem/repositories/i/conditions.dart';

class ActRepository extends DatabaseTupleRepository<ActEntity, Act> {
  Future<List<Act>> shipByMemId(
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

  Future<List<Act>> shipActive() => v(
        () async => await ship(IsNull(defColActsEnd.name)),
      );

  @override
  Act pack(UnpackedPayload unpackedPayload) {
    final actEntity = ActEntity.fromMap(unpackedPayload);

    return Act(
      actEntity.memId,
      DateAndTimePeriod(
        start: DateAndTime.from(
          actEntity.start,
          timeOfDay: actEntity.startIsAllDay ? null : actEntity.start,
        ),
        end: actEntity.end == null
            ? null
            : DateAndTime.from(
                actEntity.end!,
                timeOfDay: actEntity.endIsAllDay == true ? null : actEntity.end,
              ),
      ),
      id: actEntity.id,
      createdAt: actEntity.createdAt,
      updatedAt: actEntity.updatedAt,
      archivedAt: actEntity.archivedAt,
    );
  }

  @override
  UnpackedPayload unpack(Act payload) {
    final actEntity = ActEntity(
      payload.memId,
      payload.period.start!.dateTime,
      payload.period.start!.isAllDay,
      payload.period.end?.dateTime,
      payload.period.end?.isAllDay,
      payload.id,
      payload.createdAt,
      payload.updatedAt,
      payload.archivedAt,
    );

    return actEntity.toMap();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  ActRepository._(super.table);

  static ActRepository? _instance;

  factory ActRepository([Table? table]) =>
      _instance ??= ActRepository._(table!);

  static resetWith(ActRepository? instance) => _instance = instance;
}
