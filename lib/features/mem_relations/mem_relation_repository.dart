import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/logger/log_service.dart';

// @Deprecated('MemRelationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemRelationRepository
    extends DatabaseTupleRepository<MemRelation, int, MemRelationEntity> {
  @override
  MemRelationEntity packV2(dynamic tuple) => MemRelationEntity.fromTuple(tuple);

  Future<List<MemRelationEntity>> shipBySourceMemIdV2(int? sourceMemId) => v(
        () async => sourceMemId == null
            ? []
            : super.shipV2(
                condition: Equals(defFkMemRelationsSourceMemId, sourceMemId),
              ),
        {'sourceMemId': sourceMemId},
      );

  Future<Iterable<MemRelationEntity>> archiveByV2({
    int? relatedMemId,
    Condition? condition,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final entities = await super.shipV2(
            condition: And([
              if (relatedMemId != null)
                Or([
                  Equals(defFkMemRelationsSourceMemId, relatedMemId),
                  Equals(defFkMemRelationsTargetMemId, relatedMemId),
                ]),
              if (condition != null) condition,
            ]),
          );
          return Future.wait(
            entities.map(
              (e) => replaceV2(MemRelationEntity(
                e.sourceMemId,
                e.targetMemId,
                e.type,
                e.value,
                e.id,
                e.createdAt,
                e.updatedAt ?? DateTime.now(),
                archivedAt ?? DateTime.now(),
              )),
            ),
          );
        },
        {
          'relatedMemId': relatedMemId,
          'condition': condition,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<MemRelationEntity>> unarchiveByV2({
    int? sourceMemId,
    int? targetMemId,
    Condition? condition,
  }) =>
      v(
        () async {
          final entities = await super.shipV2(
            condition: And([
              if (sourceMemId != null)
                Equals(defFkMemRelationsSourceMemId, sourceMemId),
              if (targetMemId != null)
                Equals(defFkMemRelationsTargetMemId, targetMemId),
              if (condition != null) condition,
            ]),
          );
          return Future.wait(
            entities.map(
              (e) => replaceV2(MemRelationEntity(
                e.sourceMemId,
                e.targetMemId,
                e.type,
                e.value,
                e.id,
                e.createdAt,
                DateTime.now(),
                null,
              )),
            ),
          );
        },
        {
          'sourceMemId': sourceMemId,
          'targetMemId': targetMemId,
          'condition': condition,
        },
      );

  static MemRelationRepository? _instance;
  factory MemRelationRepository({MemRelationRepository? mock}) =>
      _instance ??= mock ?? MemRelationRepository._();
  MemRelationRepository._() : super(databaseDefinition, defTableMemRelations);
}
