import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/database.dart' as db;
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';
import 'package:mem/repositories/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<MemEntity, Mem> {
  Future<List<Mem>> shipByCondition(bool? archived, bool? done) => v(
          {
            'archived': archived,
            'done': done,
          },
          () => super.ship(
                And([
                  archived == null
                      ? null
                      : archived
                          ? IsNotNull(archivedAtColumnName)
                          : IsNull(archivedAtColumnName),
                  done == null
                      ? null
                      : done
                          ? IsNotNull(defMemDoneAt.name)
                          : IsNull(defMemDoneAt.name),
                ].whereType<Condition>()),
              ));

  @override
  UnpackedPayload unpack(Mem payload) => {
        defMemName.name: payload.name,
        defMemDoneAt.name: payload.doneAt,
        defMemStartOn.name: payload.period?.start,
        defMemStartAt.name: payload.period?.start?.isAllDay == false
            ? payload.period?.start
            : null,
        defMemEndOn.name: payload.period?.end,
        defMemEndAt.name:
            payload.period?.end?.isAllDay == false ? payload.period?.end : null,
        idColumnName: payload.id,
        createdAtColumnName: payload.createdAt,
        updatedAtColumnName: payload.updatedAt,
        archivedAtColumnName: payload.archivedAt,
      };

  @override
  Mem pack(UnpackedPayload unpackedPayload) {
    final memEntity = MemEntity.fromMap(unpackedPayload);

    final notifyOn = memEntity.notifyOn;
    final endOn = memEntity.endOn;

    return Mem(
      name: memEntity.name,
      doneAt: memEntity.doneAt,
      period: notifyOn == null && endOn == null
          ? null
          : DateAndTimePeriod(
              start: notifyOn == null
                  ? null
                  : DateAndTime.fromV2(notifyOn, timeOfDay: memEntity.notifyAt),
              end: endOn == null
                  ? null
                  : DateAndTime.fromV2(endOn, timeOfDay: memEntity.endAt),
            ),
      id: memEntity.id,
      createdAt: memEntity.createdAt,
      updatedAt: memEntity.updatedAt,
      archivedAt: memEntity.archivedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemRepository._(super.table);

  static MemRepository? _instance;

  factory MemRepository([db.Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      }
      _instance = tmp = MemRepository._(table);
    }

    return tmp;
  }

  static resetWith(MemRepository? memRepository) => _instance = memRepository;
}
