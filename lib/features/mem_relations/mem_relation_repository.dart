import 'package:drift/drift.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart'
    show
        MemRelationEntity,
        convertIntoMemRelationsInsertable,
        convertIntoMemRelationsUpdateable;
import 'package:mem/features/logger/log_service.dart';
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

  Future<MemRelationEntity> receive(MemRelation domain) => v(
        () async {
          final inserted = await driftDb.into(driftDb.memRelations).insertReturning(
                convertIntoMemRelationsInsertable(domain),
              );
          return MemRelationEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemRelationEntity> replace(MemRelationEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.memRelations)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoMemRelationsUpdateable(entity));
          return MemRelationEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<MemRelationEntity>> waste({int? sourceMemId}) => v(
        () async {
          var query = driftDb.delete(driftDb.memRelations);
          if (sourceMemId != null) {
            query = query..where((t) => t.sourceMemId.equals(sourceMemId));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(MemRelationEntity.fromTuple).toList();
        },
        {'sourceMemId': sourceMemId},
      );

  Future<Iterable<MemRelationEntity>> archiveBy({
    int? relatedMemId,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          var query = driftDb.select(driftDb.memRelations);
          if (relatedMemId != null) {
            query = query
              ..where(
                (t) =>
                    t.sourceMemId.equals(relatedMemId) |
                    t.targetMemId.equals(relatedMemId),
              );
          }
          final entities =
              (await query.get()).map(MemRelationEntity.fromTuple).toList();
          return Future.wait(
            entities.map(
              (e) => replace(
                MemRelationEntity(
                  e.sourceMemId,
                  e.targetMemId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  e.updatedAt ?? DateTime.now(),
                  archivedAt ?? DateTime.now(),
                ),
              ),
            ),
          );
        },
        {
          'relatedMemId': relatedMemId,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<MemRelationEntity>> unarchiveBy({
    int? sourceMemId,
    int? targetMemId,
    int? relatedMemId,
  }) =>
      v(
        () async {
          var query = driftDb.select(driftDb.memRelations);
          if (relatedMemId != null) {
            query = query
              ..where(
                (t) =>
                    t.sourceMemId.equals(relatedMemId) |
                    t.targetMemId.equals(relatedMemId),
              );
          } else {
            if (sourceMemId != null) {
              query = query..where((t) => t.sourceMemId.equals(sourceMemId));
            }
            if (targetMemId != null) {
              query = query..where((t) => t.targetMemId.equals(targetMemId));
            }
          }
          final entities =
              (await query.get()).map(MemRelationEntity.fromTuple).toList();
          return Future.wait(
            entities.map(
              (e) => replace(
                MemRelationEntity(
                  e.sourceMemId,
                  e.targetMemId,
                  e.type,
                  e.value,
                  e.id,
                  e.createdAt,
                  DateTime.now(),
                  null,
                ),
              ),
            ),
          );
        },
        {
          'sourceMemId': sourceMemId,
          'targetMemId': targetMemId,
          'relatedMemId': relatedMemId,
        },
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
