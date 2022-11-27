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

import '../repositories/i/_database_tuple_entity_v2.dart';

class ActRepository extends DatabaseTupleRepositoryV2<ActEntity, Act> {
  Future<List<Act>> shipByMemId(MemId memId) => v(
        {'memId': memId},
        () async => await ship(Equals(fkDefMemId.name, memId)),
      );

  @override
  Act pack(UnpackedPayload unpackedPayload) => Act(
        unpackedPayload[fkDefMemId.name],
        DateAndTimePeriod(
          start: unpackedPayload[defActStart.name] == null
              ? null
              : DateAndTime.from(
                  unpackedPayload[defActStart.name],
                  allDay: unpackedPayload[defActStartIsAllDay.name] == 1,
                ),
          end: unpackedPayload[defActEnd.name] == null
              ? null
              : DateAndTime.from(
                  unpackedPayload[defActEnd.name],
                  allDay: unpackedPayload[defActEndIsAllDay.name] == 1,
                ),
        ),
        id: unpackedPayload[idColumnName],
        createdAt: unpackedPayload[createdAtColumnName],
        updatedAt: unpackedPayload[updatedAtColumnName],
        archivedAt: unpackedPayload[archivedAtColumnName],
      );

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
