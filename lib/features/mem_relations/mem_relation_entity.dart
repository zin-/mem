import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemRelationEntity with EntityV2<MemRelation> {
  MemRelationEntity(MemRelation value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkMemRelationsSourceMemId.name: value.sourceMemId,
        defFkMemRelationsTargetMemId.name: value.targetMemId,
        defColMemRelationsType.name: value.type.name,
      };

  @override
  MemRelationEntity updatedWith(MemRelation Function(MemRelation v) update) =>
      MemRelationEntity(update(value));
}

class SavedMemRelationEntity extends MemRelationEntity
    with DatabaseTupleEntityV2<int, MemRelation> {
  SavedMemRelationEntity(Map<String, dynamic> map)
      : super(
          MemRelation.by(
            map[defFkMemRelationsSourceMemId.name],
            map[defFkMemRelationsTargetMemId.name],
            MemRelationType.values.byName(map[defColMemRelationsType.name]),
          ),
        ) {
    withMap(map);
  }
}
