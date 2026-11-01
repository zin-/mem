import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'target.dart';

class TargetEntityV1 with EntityV1<Target> {
  TargetEntityV1(Target value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'memId': value.memId,
        'type': value.targetType.name,
        'unit': value.targetUnit.name,
        'value': value.value,
        'period': value.period.name,
        'secondsAfterLastAct': value.secondsAfterLastAct,
      };

  @override
  TargetEntityV1 updatedWith(Target Function(Target v) update) =>
      TargetEntityV1(update(value));
}

class SavedTargetEntityV1 extends TargetEntityV1
    with DatabaseTupleEntityV1<int, Target> {
  SavedTargetEntityV1(Map<String, dynamic> map) : super(_targetFromMap(map)) {
    withBaseColumns(map);
  }

  SavedTargetEntityV1.fromRow(dynamic row) : super(_targetFromRow(row)) {
    withBaseColumns(row);
  }

  static Target _targetFromMap(Map<String, dynamic> map) => Target(
        memId: map['memId'] ?? map['mems_id'],
        targetType: TargetType.values.firstWhere(
          (element) => element.name == map['type'],
        ),
        targetUnit: TargetUnit.values.firstWhere(
          (element) => element.name == map['unit'],
        ),
        value: map['value'],
        period: Period.values.firstWhere(
          (element) => element.name == map['period'],
        ),
        secondsAfterLastAct: map['secondsAfterLastAct'],
      );

  static Target _targetFromRow(dynamic row) => Target(
        memId: row.memId,
        targetType: TargetType.values.firstWhere(
          (element) => element.name == row.type,
        ),
        targetUnit: TargetUnit.values.firstWhere(
          (element) => element.name == row.unit,
        ),
        value: row.value,
        period: Period.values.firstWhere(
          (element) => element.name == row.period,
        ),
        secondsAfterLastAct: row.secondsAfterLastAct,
      );

  @override
  SavedTargetEntityV1 updatedWith(Target Function(Target v) update) =>
      SavedTargetEntityV1(_savedRowFrom(this, update(value)));

  factory SavedTargetEntityV1.fromEntityV2(TargetEntity entity) =>
      SavedTargetEntityV1.fromRow(_TargetEntityRow(entity));

  TargetEntity toEntityV2() => TargetEntity(
        value.memId,
        value.targetType,
        value.targetUnit,
        value.value,
        value.period,
        id,
        createdAt,
        updatedAt,
        archivedAt,
        secondsAfterLastAct: value.secondsAfterLastAct,
      );
}

Map<String, Object?> _savedRowFrom(
  SavedTargetEntityV1 saved,
  Target value,
) =>
    {
      'id': saved.id,
      'memId': value.memId,
      'type': value.targetType.name,
      'unit': value.targetUnit.name,
      'value': value.value,
      'period': value.period.name,
      'secondsAfterLastAct': value.secondsAfterLastAct,
      'createdAt': saved.createdAt,
      'updatedAt': saved.updatedAt,
      'archivedAt': saved.archivedAt,
    };

/// Target は Mem の一要素で、単体の入り口にはならない。名前の Entity は仮。
///
/// id / createdAt / updatedAt は持つ。archivedAt は親 Mem の archive に従う想定で、
/// Target 独自には要らないかもしれない。
///
/// Act は Mem に紐づいても Act を先に見るし、Mem の削除や archive で
/// 「した事実」は消えない。だから Act は Entity でよい。
class TargetEntity implements Entity<int> {
  final MemId memId;
  final TargetType targetType;
  final TargetUnit targetUnit;
  final int value;
  final Period period;
  final int? secondsAfterLastAct;
  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  TargetEntity(
    this.memId,
    this.targetType,
    this.targetUnit,
    this.value,
    this.period,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt, {
    this.secondsAfterLastAct,
  });

  Target toDomain() => Target(
        memId: memId,
        targetType: targetType,
        targetUnit: targetUnit,
        value: value,
        period: period,
        secondsAfterLastAct: secondsAfterLastAct,
      );

  factory TargetEntity.fromTuple(dynamic row) => TargetEntity(
        row.memId,
        TargetType.values.firstWhere(
          (element) => element.name == row.type,
        ),
        TargetUnit.values.firstWhere(
          (element) => element.name == row.unit,
        ),
        row.value,
        Period.values.firstWhere(
          (element) => element.name == row.period,
        ),
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
        secondsAfterLastAct: row.secondsAfterLastAct,
      );
}

drift_database.TargetsCompanion convertIntoTargetsInsertable(Target entity) =>
    drift_database.TargetsCompanion(
      type: Value(entity.targetType.name),
      unit: Value(entity.targetUnit.name),
      value: Value(entity.value),
      period: Value(entity.period.name),
      secondsAfterLastAct: Value(entity.secondsAfterLastAct),
      memId: Value(entity.memId ?? 0),
      createdAt: Value(DateTime.now()),
    );
drift_database.TargetsCompanion convertIntoTargetsUpdateable(
  TargetEntity entity,
) =>
    drift_database.TargetsCompanion(
      id: Value(entity.id),
      type: Value(entity.targetType.name),
      unit: Value(entity.targetUnit.name),
      value: Value(entity.value),
      period: Value(entity.period.name),
      secondsAfterLastAct: Value(entity.secondsAfterLastAct),
      memId: Value(entity.memId ?? 0),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _TargetEntityRow {
  final TargetEntity entity;

  _TargetEntityRow(this.entity);

  int get id => entity.id;
  int get memId => entity.memId!;
  String get type => entity.targetType.name;
  String get unit => entity.targetUnit.name;
  int get value => entity.value;
  String get period => entity.period.name;
  int? get secondsAfterLastAct => entity.secondsAfterLastAct;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
