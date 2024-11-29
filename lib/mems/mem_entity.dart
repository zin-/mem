import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/schedule.dart';

class MemEntity extends Mem with Entity, Copyable<MemEntity> {
  MemEntity(super.name, super.doneAt, super.period);

  MemEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defColMemsName.name],
          map[defColMemsDoneAt.name],
          map[defColMemsStartOn.name] == null &&
                  map[defColMemsEndOn.name] == null
              ? null
              : DateAndTimePeriod(
                  start: map[defColMemsStartOn.name] == null
                      ? null
                      : DateAndTime.from(map[defColMemsStartOn.name],
                          timeOfDay: map[defColMemsStartAt.name]),
                  end: map[defColMemsEndOn.name] == null
                      ? null
                      : DateAndTime.from(map[defColMemsEndOn.name],
                          timeOfDay: map[defColMemsEndAt.name]),
                ),
        );

  @override
  MemEntity copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      MemEntity(
        name == null ? this.name : name(),
        doneAt == null ? this.doneAt : doneAt(),
        period == null ? this.period : period(),
      );

  @override
  Map<String, dynamic> get toMap => {
        defColMemsName.name: name,
        defColMemsDoneAt.name: doneAt,
        defColMemsStartOn.name: period?.start,
        defColMemsStartAt.name:
            period?.start?.isAllDay == true ? null : period?.start,
        defColMemsEndOn.name: period?.end,
        defColMemsEndAt.name:
            period?.end?.isAllDay == true ? null : period?.end,
      };
}

class MemEntityV2 with EntityV2<Mem> {
  MemEntityV2(Mem value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defColMemsName.name: value.name,
        defColMemsDoneAt.name: value.doneAt,
        defColMemsStartOn.name: value.period?.start,
        defColMemsStartAt.name:
            value.period?.start?.isAllDay == true ? null : value.period?.start,
        defColMemsEndOn.name: value.period?.end,
        defColMemsEndAt.name:
            value.period?.end?.isAllDay == true ? null : value.period?.end,
      };

// coverage:ignore-start
  @override
  EntityV2<Mem> updatedBy(Mem value) {
    // TODO: implement updatedBy
    throw UnimplementedError();
  }

// coverage:ignore-end

  MemEntityV2 updateWith(Mem Function(Mem mem) update) =>
      MemEntityV2(update(value));

  factory MemEntityV2.fromV1(MemEntity entity) {
    if (entity is SavedMemEntity) {
      return SavedMemEntityV2(entity.toMap);
    } else {
      return MemEntityV2(entity);
    }
  }

  MemEntity toV1() => MemEntity(value.name, value.doneAt, value.period);
}

class SavedMemEntity extends MemEntity with DatabaseTupleEntity<int> {
  SavedMemEntity(super.name, super.doneAt, super.period);

  SavedMemEntity.fromMap(
    Map<String, dynamic> map,
  ) : super.fromMap(map) {
    withMap(map);
  }

  @override
  SavedMemEntity copiedWith({
    String Function()? name,
    DateTime? Function()? doneAt,
    DateAndTimePeriod? Function()? period,
  }) =>
      SavedMemEntity.fromMap(
        toMap
          ..addAll(
            super
                .copiedWith(
                  name: name,
                  doneAt: doneAt,
                  period: period,
                )
                .toMap,
          ),
      );
}

class SavedMemEntityV2 extends MemEntityV2
    with DatabaseTupleEntityV2<int, Mem> {
  SavedMemEntityV2(Map<String, dynamic> map)
      : super(
          Mem(
            map[defColMemsName.name],
            map[defColMemsDoneAt.name],
            map[defColMemsStartOn.name] == null &&
                    map[defColMemsEndOn.name] == null
                ? null
                : DateAndTimePeriod(
                    start: map[defColMemsStartOn.name] == null
                        ? null
                        : DateAndTime.from(map[defColMemsStartOn.name],
                            timeOfDay: map[defColMemsStartAt.name]),
                    end: map[defColMemsEndOn.name] == null
                        ? null
                        : DateAndTime.from(map[defColMemsEndOn.name],
                            timeOfDay: map[defColMemsEndAt.name]),
                  ),
          ),
        ) {
    withMap(map);
  }

  @override
  SavedMemEntityV2 updateWith(Mem Function(Mem mem) update) =>
      SavedMemEntityV2(toMap..addAll(MemEntityV2(update(value)).toMap));

  Iterable<Schedule> periodSchedules(
    TimeOfDay startOfDay,
  ) =>
      v(
        () {
          return [
            Schedule.of(
              id,
              value.period?.start?.isAllDay == true
                  ? DateTime(
                      value.period!.start!.year,
                      value.period!.start!.month,
                      value.period!.start!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                  : value.period?.start,
              NotificationType.startMem,
            ),
            Schedule.of(
              id,
              value.period?.end?.isAllDay == true
                  ? DateTime(
                      value.period!.end!.year,
                      value.period!.end!.month,
                      value.period!.end!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                      .add(const Duration(days: 1))
                      .subtract(const Duration(minutes: 1))
                  : value.period?.end,
              NotificationType.endMem,
            ),
          ];
        },
        {
          'this': this,
          'startOfDay': startOfDay,
        },
      );

  @override
  SavedMemEntity toV1() => SavedMemEntity.fromMap(toMap);

  factory SavedMemEntityV2.fromV1(SavedMemEntity entity) {
    return SavedMemEntityV2(entity.toMap);
  }
}
