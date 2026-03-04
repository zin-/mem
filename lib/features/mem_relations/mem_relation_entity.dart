import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
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
        defFkMemRelationsSourceMemId.name: value.sourceMemId,
        defFkMemRelationsTargetMemId.name: value.targetMemId,
        defColMemRelationsType.name: value.type.name,
        defColMemRelationsValue.name: value.value,
      };

  @override
  MemRelationEntityV1 updatedWith(MemRelation Function(MemRelation v) update) =>
      MemRelationEntityV1(update(value));
}

class SavedMemRelationEntityV1 extends MemRelationEntityV1
    with DatabaseTupleEntityV1<int, MemRelation> {
  SavedMemRelationEntityV1(Map<String, dynamic> map)
      : super(
          MemRelation.by(
            map[defFkMemRelationsSourceMemId.name],
            map[defFkMemRelationsTargetMemId.name],
            MemRelationType.values.byName(map[defColMemRelationsType.name]),
            map[defColMemRelationsValue.name] ?? 0,
          ),
        ) {
    withMap(map);
  }

  factory SavedMemRelationEntityV1.fromEntityV2(MemRelationEntity entity) =>
      SavedMemRelationEntityV1(
        {
          defFkMemRelationsSourceMemId.name: entity.sourceMemId,
          defFkMemRelationsTargetMemId.name: entity.targetMemId,
          defColMemRelationsType.name: entity.type.name,
          defColMemRelationsValue.name: entity.value,
          defPkId.name: entity.id,
          defColCreatedAt.name: entity.createdAt,
          defColUpdatedAt.name: entity.updatedAt,
          defColArchivedAt.name: entity.archivedAt,
        },
      );
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

  factory MemRelationEntity.fromTuple(dynamic tuple) => MemRelationEntity(
        tuple.sourceMemId,
        tuple.targetMemId,
        MemRelationType.values.firstWhere(
          (element) => element.name == tuple.type,
        ),
        tuple.value,
        tuple.id,
        tuple.createdAt,
        tuple.updatedAt,
        tuple.archivedAt,
      );
}

convertIntoMemRelationsInsertable(MemRelation entity) =>
    drift_database.MemRelationsCompanion(
      sourceMemId: Value(entity.sourceMemId),
      targetMemId: Value(entity.targetMemId),
      type: Value(entity.type.name),
      value: Value(entity.value),
      createdAt: Value(DateTime.now()),
    );
convertIntoMemRelationsUpdateable(MemRelationEntity entity) =>
    drift_database.MemRelationsCompanion(
      sourceMemId: Value(entity.sourceMemId ?? 0),
      targetMemId: Value(entity.targetMemId ?? 0),
      type: Value(entity.type.name),
      value: Value(entity.value),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );
