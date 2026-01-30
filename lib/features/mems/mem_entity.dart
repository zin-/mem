import 'package:flutter/material.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/schedule.dart';

class MemEntityV1 with EntityV1<Mem> {
  MemEntityV1(Mem value) {
    this.value = value;

    entityChildrenRelation[MemEntityV1] ??= {
      MemItemEntity,
      ActEntity,
      MemNotificationEntity,
      TargetEntity,
      MemRelationEntity,
    };
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

  @override
  MemEntityV1 updatedWith(Mem Function(Mem mem) update) =>
      MemEntityV1(update(value));
}

class SavedMemEntityV1 extends MemEntityV1
    with DatabaseTupleEntityV1<int, Mem> {
  SavedMemEntityV1(Map<String, dynamic> map)
      : super(
          Mem(
            map[defPkId.name],
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
  SavedMemEntityV1 updatedWith(Mem Function(Mem mem) update) =>
      SavedMemEntityV1(toMap..addAll(MemEntityV1(update(value)).toMap));

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
}

class MemEntity implements Entity<int> {
  @override
  final int id;
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  MemEntity(this.id, this.name, this.doneAt, this.period);
}
