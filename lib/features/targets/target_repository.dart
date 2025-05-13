import 'package:mem/databases/definition.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';

class TargetRepository
    extends DatabaseTupleRepositoryV2<TargetEntity, SavedTargetEntity> {
  TargetRepository() : super(databaseDefinition, defTableTargets);

  @override
  SavedTargetEntity pack(Map<String, dynamic> map) => SavedTargetEntity(map);
}
