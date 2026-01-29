import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemRelationEntity with EntityV1<MemRelation> {
  MemRelationEntity(MemRelation value) {
    this.value = value;
  }

  factory MemRelationEntity.by(
    int? sourceMemId,
    int targetMemId,
    MemRelationType type,
    int value,
  ) =>
      MemRelationEntity(
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
  MemRelationEntity updatedWith(MemRelation Function(MemRelation v) update) =>
      MemRelationEntity(update(value));
}

class SavedMemRelationEntity extends MemRelationEntity
    with DatabaseTupleEntityV1<int, MemRelation> {
  SavedMemRelationEntity(Map<String, dynamic> map)
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
}
