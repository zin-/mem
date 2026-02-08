import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

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

  MemEntity toEntityV2() => MemEntity(
        id,
        value.name,
        value.doneAt,
        value.period,
        createdAt,
        updatedAt,
        archivedAt,
      );

  factory SavedMemEntityV1.fromEntityV2(MemEntity entity) => SavedMemEntityV1(
        {
          defPkId.name: entity.id,
          defColMemsName.name: entity.name,
          defColMemsDoneAt.name: entity.doneAt,
          defColMemsStartOn.name: entity.period?.start,
          defColMemsStartAt.name: entity.period?.start?.isAllDay == true
              ? null
              : entity.period?.start,
          defColMemsEndOn.name: entity.period?.end,
          defColMemsEndAt.name:
              entity.period?.end?.isAllDay == true ? null : entity.period?.end,
          defColCreatedAt.name: entity.createdAt,
          defColUpdatedAt.name: entity.updatedAt,
          defColArchivedAt.name: entity.archivedAt,
        },
      );
}

class MemEntity implements Entity<int> {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemEntity(
    this.id,
    this.name,
    this.doneAt,
    this.period,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  Mem toDomain() => Mem(
        id,
        name,
        doneAt,
        period,
      );
}
