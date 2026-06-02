import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class ActEntityV1 with EntityV1<Act> {
  ActEntityV1(Act value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'memId': value.memId,
        'start': value.period?.start,
        'startIsAllDay': value.period?.start?.isAllDay,
        'end': value.period?.end,
        'endIsAllDay': value.period?.end?.isAllDay,
        'pausedAt': value.pausedAt,
        'actKind': value.actKind?.name,
      };

  @override
  ActEntityV1 updatedWith(Act Function(Act v) update) =>
      ActEntityV1(update(value));
}

class SavedActEntityV1 extends ActEntityV1
    with DatabaseTupleEntityV1<int, Act> {
  SavedActEntityV1(Map<String, dynamic> map)
      : super(_actFromMap(map)) {
    withBaseColumns(map);
  }

  SavedActEntityV1.fromRow(dynamic row)
      : super(_actFromRow(row)) {
    withBaseColumns(row);
  }

  static Act _actFromMap(Map<String, dynamic> map) => Act.by(
        map['memId'] ?? map['mems_id'],
        startWhen: map['start'] == null
            ? null
            : DateAndTime.from(
                map['start'],
                timeOfDay: (map['startIsAllDay'] ?? map['start_is_all_day']) ==
                        true
                    ? null
                    : map['start'],
              ),
        endWhen: map['end'] == null
            ? null
            : DateAndTime.from(
                map['end'],
                timeOfDay:
                    (map['endIsAllDay'] ?? map['end_is_all_day']) == true
                        ? null
                        : map['end'],
              ),
        pausedAt: map['pausedAt'] ?? map['paused_at'],
        completionKind: map.containsKey('actKind') ||
                map.containsKey('act_kind')
            ? actKindFromStored(map['actKind'] ?? map['act_kind'])
            : null,
        completionKindFromRow: map.containsKey('actKind') ||
            map.containsKey('act_kind'),
      );

  static Act _actFromRow(dynamic row) => Act.by(
        row.memId,
        startWhen: row.start == null
            ? null
            : DateAndTime.from(
                row.start,
                timeOfDay: row.startIsAllDay == true ? null : row.start,
              ),
        endWhen: row.end == null
            ? null
            : DateAndTime.from(
                row.end,
                timeOfDay: row.endIsAllDay == true ? null : row.end,
              ),
        pausedAt: row.pausedAt,
        completionKind: row.actKind == null
            ? null
            : actKindFromStored(row.actKind),
        completionKindFromRow: row.actKind != null,
      );

  @override
  SavedActEntityV1 updatedWith(Act Function(Act v) update) =>
      SavedActEntityV1.fromRow(_savedRowFrom(this, update(value)));

  factory SavedActEntityV1.fromEntityV2(ActEntity entity) {
    final saved = SavedActEntityV1.fromRow(_ActEntityRow(entity));
    return saved;
  }

  ActEntity toEntityV2() => ActEntity(
        value.memId,
        value.period?.start,
        value.period?.end,
        value.pausedAt,
        id,
        createdAt,
        updatedAt,
        archivedAt,
        actKind: value.actKind,
      );
}

Map<String, Object?> _savedRowFrom(
  SavedActEntityV1 saved,
  Act value,
) =>
    {
      'id': saved.id,
      'memId': value.memId,
      'start': value.period?.start,
      'startIsAllDay': value.period?.start?.isAllDay,
      'end': value.period?.end,
      'endIsAllDay': value.period?.end?.isAllDay,
      'pausedAt': value.pausedAt,
      'actKind': value.actKind?.name,
      'createdAt': saved.createdAt,
      'updatedAt': saved.updatedAt,
      'archivedAt': saved.archivedAt,
    };

class ActEntity implements Entity<int> {
  final MemId memId;
  final DateAndTime? start;
  final DateAndTime? end;
  final DateTime? pausedAt;
  final ActKind? actKind;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  ActEntity(
    this.memId,
    this.start,
    this.end,
    this.pausedAt,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt, {
    this.actKind,
  });

  Act toDomain() => Act.by(
        memId!,
        startWhen: start,
        endWhen: end,
        pausedAt: pausedAt,
        completionKind: actKind,
        completionKindFromRow: true,
      );

  factory ActEntity.fromTuple(dynamic row) => ActEntity(
        row.memId,
        row.start == null
            ? null
            : DateAndTime.from(
                row.start,
                timeOfDay: row.startIsAllDay == true ? null : row.start,
              ),
        row.end == null
            ? null
            : DateAndTime.from(
                row.end,
                timeOfDay: row.endIsAllDay == true ? null : row.end,
              ),
        row.pausedAt,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
        actKind: actKindFromStored(row.actKind),
      );

  ActEntity updatedWith(Act act) => ActEntity(
        memId,
        act.period?.start,
        act.period?.end,
        act.pausedAt,
        id,
        createdAt,
        updatedAt,
        archivedAt,
        actKind: act.actKind,
      );
}

drift_database.ActsCompanion convertIntoActsInsertable(
  Act entity, {
  DateTime? createdAt,
}) =>
    drift_database.ActsCompanion(
      memId: Value(entity.memId),
      start: Value(entity.period?.start),
      startIsAllDay: Value(entity.period?.start?.isAllDay),
      end: Value(entity.period?.end),
      endIsAllDay: Value(entity.period?.end?.isAllDay),
      pausedAt: Value(entity.pausedAt),
      actKind: Value(entity.actKind?.name),
      createdAt: Value(createdAt ?? DateTime.now()),
    );
drift_database.ActsCompanion convertIntoActsUpdateable(ActEntity entity) =>
    drift_database.ActsCompanion(
      start: Value(entity.start),
      startIsAllDay: Value(entity.start?.isAllDay),
      end: Value(entity.end),
      endIsAllDay: Value(entity.end?.isAllDay),
      pausedAt: Value(entity.pausedAt),
      actKind: Value(entity.actKind?.name),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _ActEntityRow {
  final ActEntity entity;

  _ActEntityRow(this.entity);

  int get id => entity.id;
  int get memId => entity.memId!;
  DateTime? get start => entity.start;
  bool? get startIsAllDay => entity.start?.isAllDay;
  DateTime? get end => entity.end;
  bool? get endIsAllDay => entity.end?.isAllDay;
  DateTime? get pausedAt => entity.pausedAt;
  String? get actKind => entity.actKind?.name;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
