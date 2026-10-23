import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('MemRelationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemRelationRepository extends DriftRepository {
  Future<List<MemRelationEntity>> shipBySourceMemId(int? sourceMemId) => v(
        () async {
          if (sourceMemId == null) return [];
          final rows = await (driftDb.select(driftDb.memRelations)
                ..where((t) => t.sourceMemId.equals(sourceMemId)))
              .get();
          return rows.map(MemRelationEntity.fromTuple).toList();
        },
        {'sourceMemId': sourceMemId},
      );

  MemRelationRepository._();

  factory MemRelationRepository({MemRelationRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemRelationRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemRelationRepository._());
  }
}
