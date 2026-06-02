import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;

import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'mem_notification.dart';

class MemNotificationEntityV1 with EntityV1<MemNotification> {
  MemNotificationEntityV1(MemNotification value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'memId': value.memId,
        'type': value.type.name,
        'timeOfDaySeconds': value.time,
        'message': value.message,
      };

  @override
  MemNotificationEntityV1 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      MemNotificationEntityV1(update(value));
}

class SavedMemNotificationEntityV1 extends MemNotificationEntityV1
    with DatabaseTupleEntityV1<int, MemNotification> {
  SavedMemNotificationEntityV1(Map<String, dynamic> map)
      : super(_notificationFromMap(map)) {
    withBaseColumns(map);
  }

  SavedMemNotificationEntityV1.fromRow(dynamic row)
      : super(_notificationFromRow(row)) {
    withBaseColumns(row);
  }

  static MemNotification _notificationFromMap(Map<String, dynamic> map) =>
      MemNotification.by(
        map['memId'] ?? map['mems_id'],
        MemNotificationType.fromName(map['type']),
        map['timeOfDaySeconds'] ?? map['time_of_day_seconds'],
        map['message'],
      );

  static MemNotification _notificationFromRow(dynamic row) =>
      MemNotification.by(
        row.memId,
        MemNotificationType.fromName(row.type),
        row.timeOfDaySeconds,
        row.message,
      );

  @override
  SavedMemNotificationEntityV1 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      SavedMemNotificationEntityV1.fromRow(_savedRowFrom(this, update(value)));

  factory SavedMemNotificationEntityV1.fromEntityV2(
          MemNotificationEntity entity) =>
      SavedMemNotificationEntityV1.fromRow(_MemNotificationEntityRow(entity));

  MemNotificationEntity toEntityV2() => MemNotificationEntity(
        value.memId,
        value.type,
        value.time,
        value.message,
        id,
        createdAt,
        updatedAt,
        archivedAt,
      );
}

Map<String, Object?> _savedRowFrom(
  SavedMemNotificationEntityV1 saved,
  MemNotification value,
) =>
    {
      'id': saved.id,
      'memId': value.memId,
      'type': value.type.name,
      'timeOfDaySeconds': value.time,
      'message': value.message,
      'createdAt': saved.createdAt,
      'updatedAt': saved.updatedAt,
      'archivedAt': saved.archivedAt,
    };

class MemNotificationEntity implements Entity<int> {
  final MemId memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemNotificationEntity(
    this.memId,
    this.type,
    this.time,
    this.message,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  factory MemNotificationEntity.fromTuple(dynamic row) =>
      MemNotificationEntity(
        row.memId,
        MemNotificationType.fromName(row.type),
        row.timeOfDaySeconds,
        row.message,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
      );

  MemNotification toDomain() => MemNotification(
        memId,
        type,
        time,
        message,
      );
}

drift_database.MemRepeatedNotificationsCompanion
    convertIntoMemRepeatedNotificationsInsertable(
  MemNotification entity, {
  DateTime? createdAt,
}) =>
    drift_database.MemRepeatedNotificationsCompanion(
      memId: Value(entity.memId ?? 0),
      timeOfDaySeconds: Value(entity.time ?? 0),
      type: Value(entity.type.name),
      message: Value(entity.message),
      createdAt: Value(createdAt ?? DateTime.now()),
    );
drift_database.MemRepeatedNotificationsCompanion
    convertIntoMemRepeatedNotificationsUpdateable(
  MemNotificationEntity entity,
) =>
    drift_database.MemRepeatedNotificationsCompanion(
      memId: Value(entity.memId ?? 0),
      timeOfDaySeconds: Value(entity.time ?? 0),
      type: Value(entity.type.name),
      message: Value(entity.message),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _MemNotificationEntityRow {
  final MemNotificationEntity entity;

  _MemNotificationEntityRow(this.entity);

  int get id => entity.id;
  int get memId => entity.memId!;
  String get type => entity.type.name;
  int? get timeOfDaySeconds => entity.time;
  String get message => entity.message;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
