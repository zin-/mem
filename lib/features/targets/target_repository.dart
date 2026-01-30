import 'package:mem/databases/definition.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';

// @Deprecated('TargetRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class TargetRepository
    extends DatabaseTupleRepository<TargetEntity, SavedTargetEntity, Target> {
  @override
  SavedTargetEntity pack(Map<String, dynamic> map) => SavedTargetEntity(map);

  static TargetRepository? _instance;
  factory TargetRepository({TargetRepository? mock}) =>
      _instance ??= mock ?? TargetRepository._();
  TargetRepository._() : super(databaseDefinition, defTableTargets);
}
