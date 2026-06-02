import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemEntityV1 with EntityV1<Mem> {
  MemEntityV1(Mem value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'name': value.name,
        'doneAt': value.doneAt,
        'notifyOn': value.period?.start,
        'notifyAt':
            value.period?.start?.isAllDay == true ? null : value.period?.start,
        'endOn': value.period?.end,
        'endAt': value.period?.end?.isAllDay == true ? null : value.period?.end,
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
  }) : super(_memFromMap(map)) {
    withBaseColumns(map);
  }

  SavedMemEntityV1.fromRow(
    dynamic row, {
    this.latestAct,
  }) : super(_memFromRow(row)) {
    withBaseColumns(row);
  }

  static Mem _memFromMap(Map<String, dynamic> map) => Mem(
        map['id'],
        map['name'],
        map['doneAt'],
        map['notifyOn'] == null && map['endOn'] == null
            ? null
            : DateAndTimePeriod(
                start: map['notifyOn'] == null
                    ? null
                    : DateAndTime.from(
                        map['notifyOn'],
                        timeOfDay: map['notifyAt'],
                      ),
                end: map['endOn'] == null
                    ? null
                    : DateAndTime.from(
                        map['endOn'],
                        timeOfDay: map['endAt'],
                      ),
              ),
      );

  static Mem _memFromRow(dynamic row) => Mem(
        row.id,
        row.name,
        row.doneAt,
        row.notifyOn == null && row.endOn == null
            ? null
            : DateAndTimePeriod(
                start: row.notifyOn == null
                    ? null
                    : DateAndTime.from(
                        row.notifyOn,
                        timeOfDay: row.notifyAt == null
                            ? null
                            : DateAndTime.from(row.notifyAt),
                      ),
                end: row.endOn == null
                    ? null
                    : DateAndTime.from(
                        row.endOn,
                        timeOfDay: row.endAt == null
                            ? null
                            : DateAndTime.from(row.endAt),
                      ),
              ),
      );

  @override
  SavedMemEntityV1 updatedWith(Mem Function(Mem mem) update) =>
      SavedMemEntityV1.fromRow(
        _savedRowFrom(this, update(value)),
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

  factory SavedMemEntityV1.fromEntityV2(MemEntity entity) =>
      SavedMemEntityV1.fromRow(
        _MemEntityRow(entity),
        latestAct: entity.latestAct,
      );
}

Map<String, Object?> _savedRowFrom(
  SavedMemEntityV1 saved,
  Mem value,
) =>
    {
      'id': saved.id,
      'name': value.name,
      'doneAt': value.doneAt,
      'notifyOn': value.period?.start,
      'notifyAt':
          value.period?.start?.isAllDay == true ? null : value.period?.start,
      'endOn': value.period?.end,
      'endAt': value.period?.end?.isAllDay == true ? null : value.period?.end,
      'createdAt': saved.createdAt,
      'updatedAt': saved.updatedAt,
      'archivedAt': saved.archivedAt,
    };

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
    dynamic row, {
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
      row.id,
      row.name,
      row.doneAt,
      row.notifyOn == null && row.endOn == null
          ? null
          : DateAndTimePeriod(
              start: row.notifyOn == null
                  ? null
                  : DateAndTime.from(
                      row.notifyOn,
                      timeOfDay: row.notifyAt == null
                          ? null
                          : DateAndTime.from(row.notifyAt),
                    ),
              end: row.endOn == null
                  ? null
                  : DateAndTime.from(
                      row.endOn,
                      timeOfDay: row.endAt == null
                          ? null
                          : DateAndTime.from(row.endAt),
                    ),
            ),
      memItems,
      row.createdAt,
      row.updatedAt,
      row.archivedAt,
      repeatedNotifications: repeatedNotifications,
      memRelations: memRelations,
      latestAct: latestAct,
    );
  }
}

class _MemEntityRow {
  final MemEntity entity;

  _MemEntityRow(this.entity);

  int get id => entity.id;
  String get name => entity.name;
  DateTime? get doneAt => entity.doneAt;
  DateTime? get notifyOn => entity.period?.start;
  DateTime? get notifyAt =>
      entity.period?.start?.isAllDay == true ? null : entity.period?.start;
  DateTime? get endOn => entity.period?.end;
  DateTime? get endAt =>
      entity.period?.end?.isAllDay == true ? null : entity.period?.end;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
