import 'package:mem/acts/act_entity.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/database.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';

class ActRepository extends DatabaseTupleRepositoryV2<ActEntity, Act> {
  Future<List<Act>> shipByMemId(
    MemId memId, {
    DateAndTimePeriod? period,
  }) =>
      v(
        {'memId': memId, 'period': period},
        () async {
          if (period == null) {
            return await ship(Equals(fkDefMemId.name, memId));
          } else {
            return await ship(And([
              Equals(fkDefMemId.name, memId),
              GraterThanOrEqual(defActStart, period.start),
              LessThan(defActStart, period.end),
            ]));
          }
        },
      );

  @override
  Act pack(UnpackedPayload unpackedPayload) {
    final actEntity = ActEntity.fromMap(unpackedPayload);

    return Act(
      actEntity.memId,
      DateAndTimePeriod(
        start: DateAndTime.from(
          actEntity.start,
          allDay: actEntity.startIsAllDay,
        ),
        end: actEntity.end == null
            ? null
            : DateAndTime.from(
                actEntity.end!,
                allDay: actEntity.endIsAllDay!,
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

  factory ActRepository([Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      }
      _instance = tmp = ActRepository._(table);
    }

    return tmp;
  }

  static reset() => _instance = null;
}
