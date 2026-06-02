import 'package:drift/drift.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/databases/database.dart' as drift_database;

class MemRelationEntityV1 with EntityV1<MemRelation> {
  MemRelationEntityV1(MemRelation value) {
    this.value = value;
  }

  factory MemRelationEntityV1.by(
    int? sourceMemId,
    int targetMemId,
    MemRelationType type,
    int value,
  ) =>
      MemRelationEntityV1(
        MemRelation.by(
          sourceMemId ?? 0,
          targetMemId,
          type,
          value,
        ),
      );

  @override
  Map<String, Object?> get toMap => {
        'sourceMemId': value.sourceMemId,
        'targetMemId': value.targetMemId,
        'type': value.type.name,
        'value': value.value,
      };

  @override
  MemRelationEntityV1 updatedWith(MemRelation Function(MemRelation v) update) =>
      MemRelationEntityV1(update(value));
}

class SavedMemRelationEntityV1 extends MemRelationEntityV1
    with DatabaseTupleEntityV1<int, MemRelation> {
  SavedMemRelationEntityV1(Map<String, dynamic> map)
      : super(_relationFromMap(map)) {
    withBaseColumns(map);
  }

  SavedMemRelationEntityV1.fromRow(dynamic row) : super(_relationFromRow(row)) {
    withBaseColumns(row);
  }

  static MemRelation _relationFromMap(Map<String, dynamic> map) =>
      MemRelation.by(
        map['sourceMemId'] ?? map['source_mems_id'],
        map['targetMemId'] ?? map['target_mems_id'],
        MemRelationType.values.byName(map['type']),
        map['value'] ?? 0,
      );

  static MemRelation _relationFromRow(dynamic row) => MemRelation.by(
        row.sourceMemId,
        row.targetMemId,
        MemRelationType.values.byName(row.type),
        row.value ?? 0,
      );

  factory SavedMemRelationEntityV1.fromEntityV2(MemRelationEntity entity) =>
      SavedMemRelationEntityV1.fromRow(_MemRelationEntityRow(entity));

  MemRelationEntity toEntityV2() => MemRelationEntity(
        value.sourceMemId,
        value.targetMemId,
        value.type,
        value.value,
        id,
        createdAt,
        updatedAt,
        archivedAt,
      );
}

class MemRelationEntity implements Entity<int> {
  final MemId sourceMemId;
  final MemId targetMemId;
  final MemRelationType type;
  final int value;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemRelationEntity(
    this.sourceMemId,
    this.targetMemId,
    this.type,
    this.value,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  factory MemRelationEntity.fromTuple(dynamic row) => MemRelationEntity(
        row.sourceMemId,
        row.targetMemId,
        MemRelationType.values.firstWhere(
          (element) => element.name == row.type,
        ),
        row.value,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
      );
}

drift_database.MemRelationsCompanion convertIntoMemRelationsInsertable(
  MemRelation entity,
) =>
    drift_database.MemRelationsCompanion(
      sourceMemId: Value(entity.sourceMemId),
      targetMemId: Value(entity.targetMemId),
      type: Value(entity.type.name),
      value: Value(entity.value),
      createdAt: Value(DateTime.now()),
    );
drift_database.MemRelationsCompanion convertIntoMemRelationsUpdateable(
  MemRelationEntity entity,
) =>
    drift_database.MemRelationsCompanion(
      sourceMemId: Value(entity.sourceMemId ?? 0),
      targetMemId: Value(entity.targetMemId ?? 0),
      type: Value(entity.type.name),
      value: Value(entity.value),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _MemRelationEntityRow {
  final MemRelationEntity entity;

  _MemRelationEntityRow(this.entity);

  int get id => entity.id;
  int get sourceMemId => entity.sourceMemId!;
  int get targetMemId => entity.targetMemId!;
  String get type => entity.type.name;
  int get value => entity.value;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
