import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';
import 'package:mem/repositories/mem_entity.dart';

class MemRepository extends DatabaseTupleRepositoryV2<MemEntity, Mem> {
  Future<List<Mem>> shipByCondition(bool? archived, bool? done) => v(
        () => super.ship(
          And([
            archived == null
                ? null
                : archived
                    ? IsNotNull(defColArchivedAt.name)
                    : IsNull(defColArchivedAt.name),
            done == null
                ? null
                : done
                    ? IsNotNull(defColMemsDoneAt.name)
                    : IsNull(defColMemsDoneAt.name),
          ].whereType<Condition>()),
        ),
        {
          'archived': archived,
          'done': done,
        },
      );

  @override
  Map<String, dynamic> unpack(Mem payload) => {
        defColMemsName.name: payload.name,
        defColMemsDoneAt.name: payload.doneAt,
        defColMemsStartOn.name: payload.period?.start,
        defColMemsStartAt.name: payload.period?.start?.isAllDay == false
            ? payload.period?.start
            : null,
        defColMemsEndOn.name: payload.period?.end,
        defColMemsEndAt.name:
            payload.period?.end?.isAllDay == false ? payload.period?.end : null,
        defPkId.name: payload.id,
        defColCreatedAt.name: payload.createdAt,
        defColUpdatedAt.name: payload.updatedAt,
        defColArchivedAt.name: payload.archivedAt,
      };

  @override
  Mem pack(Map<String, dynamic> unpackedPayload) {
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
                  : DateAndTime.from(notifyOn, timeOfDay: memEntity.notifyAt),
              end: endOn == null
                  ? null
                  : DateAndTime.from(endOn, timeOfDay: memEntity.endAt),
            ),
      id: memEntity.id,
      createdAt: memEntity.createdAt,
      updatedAt: memEntity.updatedAt,
      archivedAt: memEntity.archivedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  MemRepository._() : super(defTableMems);

  static MemRepository? _instance;

  factory MemRepository() => _instance ??= MemRepository._();

  static resetWith(MemRepository? memRepository) => _instance = memRepository;
}
