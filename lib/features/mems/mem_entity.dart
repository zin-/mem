import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemEntityV1 with EntityV1<Mem> {
  MemEntityV1(Mem value) {
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

  @override
  MemEntityV1 updatedWith(Mem Function(Mem mem) update) =>
      MemEntityV1(update(value));
}

class SavedMemEntityV1 extends MemEntityV1
    with DatabaseTupleEntityV1<int, Mem> {
  final Act? latestAct;

  SavedMemEntityV1(
    Map<String, dynamic> map, {
    this.latestAct,
  }) : super(
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
      SavedMemEntityV1(
        toMap..addAll(MemEntityV1(update(value)).toMap),
        latestAct: latestAct,
      );

  MemEntity toEntityV2() => MemEntity(
        id,
        value.name,
        value.doneAt,
        value.period,
        null,
        createdAt,
        updatedAt,
        archivedAt,
        latestAct: latestAct,
        repeatedNotifications: null,
        memRelations: null,
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
        latestAct: entity.latestAct,
      );
}

class MemEntity implements Entity<int> {
  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;
  final List<MemItemEntity>? items;
  final List<MemNotificationEntity>? repeatedNotifications;
  final List<MemRelationEntity>? memRelations;
  final Act? latestAct;

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
    this.items,
    this.createdAt,
    this.updatedAt,
    this.archivedAt, {
    this.repeatedNotifications,
    this.memRelations,
    this.latestAct,
  });

  Mem toDomain() => Mem(
        id,
        name,
        doneAt,
        period,
        latestAct: latestAct,
      );

  MemEntity updatedWith({
    Mem Function(Mem mem)? update,
    List<MemItemEntity>? Function()? items,
    List<MemNotificationEntity>? Function()? repeatedNotifications,
    List<MemRelationEntity>? Function()? memRelations,
    Act? Function()? latestAct,
    DateTime? Function()? updatedAt,
    DateTime? Function()? archivedAt,
  }) {
    final updated = update == null ? toDomain() : update(toDomain());
    return MemEntity(
      id,
      updated.name,
      updated.doneAt,
      updated.period,
      items == null ? this.items : items(),
      createdAt,
      updatedAt == null ? this.updatedAt : updatedAt(),
      archivedAt == null ? this.archivedAt : archivedAt(),
      repeatedNotifications: repeatedNotifications == null
          ? this.repeatedNotifications
          : repeatedNotifications(),
      memRelations: memRelations == null ? this.memRelations : memRelations(),
      latestAct: latestAct == null ? this.latestAct : latestAct(),
    );
  }

  factory MemEntity.fromTuple(
    dynamic tuple, {
    Map<String, dynamic> children = const {},
  }) {
    final memItemsRaw = children['mem_items'];
    final memItems = memItemsRaw == null
        ? null
        : List<MemItemEntity>.from(memItemsRaw as List);
    final notifRaw = children['mem_repeated_notifications'];
    final repeatedNotifications = notifRaw == null
        ? null
        : List<MemNotificationEntity>.from(notifRaw as List);
    final relRaw = children['mem_relations'];
    final memRelations =
        relRaw == null ? null : List<MemRelationEntity>.from(relRaw as List);
    final latestActRaw = children['latest_act'];
    Act? latestAct;
    final latestList = latestActRaw as List?;
    if (latestList != null && latestList.isNotEmpty) {
      latestAct = (latestList.first as ActEntity).toDomain();
    }

    return MemEntity(
      tuple.id,
      tuple.name,
      tuple.doneAt,
      tuple.notifyOn == null && tuple.endOn == null
          ? null
          : DateAndTimePeriod(
              start: tuple.notifyOn == null
                  ? null
                  : DateAndTime.from(
                      tuple.notifyOn,
                      timeOfDay: tuple.notifyAt == null
                          ? null
                          : DateAndTime.from(tuple.notifyAt),
                    ),
              end: tuple.endOn == null
                  ? null
                  : DateAndTime.from(
                      tuple.endOn,
                      timeOfDay: tuple.endAt == null
                          ? null
                          : DateAndTime.from(tuple.endAt),
                    ),
            ),
      memItems,
      tuple.createdAt,
      tuple.updatedAt,
      tuple.archivedAt,
      repeatedNotifications: repeatedNotifications,
      memRelations: memRelations,
      latestAct: latestAct,
    );
  }
}
