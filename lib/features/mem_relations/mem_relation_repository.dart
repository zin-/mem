import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';

class MemRelationRepository extends DatabaseTupleRepositoryV2<MemRelationEntity,
    SavedMemRelationEntity> {
  MemRelationRepository() : super(databaseDefinition, defTableMemRelations);

  @override
  SavedMemRelationEntity pack(Map<String, dynamic> map) =>
      SavedMemRelationEntity(map);
}
