import 'package:mem/databases/definition.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('TargetRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class TargetRepository
    extends DatabaseTupleRepository<Target, int, TargetEntity> {
  TargetRepository._() : super(databaseDefinition, defTableTargets);

  factory TargetRepository({TargetRepository? mock}) {
    if (mock != null) {
      Singleton.override<TargetRepository>(mock);
      return mock;
    }
    return Singleton.of(() => TargetRepository._());
  }
}
