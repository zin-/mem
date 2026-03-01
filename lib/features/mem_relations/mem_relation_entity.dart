import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

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
}
