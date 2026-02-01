import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';

// @Deprecated('MemRelationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemRelationRepository extends DatabaseTupleRepository<
    MemRelationEntity,
    SavedMemRelationEntity,
    MemRelation,
    int,
    // FIXME MemRelationentityを定義して置き換える
    MemEntity> {
  @override
  SavedMemRelationEntity pack(Map<String, dynamic> map) =>
      SavedMemRelationEntity(map);

  @override
  Future<List<SavedMemRelationEntity>> ship({
    int? sourceMemId,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async => await super.ship(
          condition: And([
            if (sourceMemId != null)
              Equals(defFkMemRelationsSourceMemId, sourceMemId),
            if (condition != null) condition,
          ]),
        ),
        {'sourceMemId': sourceMemId},
      );

  Future<Iterable<SavedMemRelationEntity>> archiveBy({
    int? relatedMemId,
    Condition? condition,
    DateTime? archivedAt,
  }) =>
      v(
        () async => await ship(
          condition: And([
            if (relatedMemId != null)
              Or([
                Equals(defFkMemRelationsSourceMemId, relatedMemId),
                Equals(defFkMemRelationsTargetMemId, relatedMemId),
              ]),
            if (condition != null) condition,
          ]),
        ).then((v) =>
            Future.wait(v.map((e) => archive(e, archivedAt: archivedAt)))),
        {
          'relatedMemId': relatedMemId,
          'condition': condition,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<SavedMemRelationEntity>> unarchiveBy({
    int? sourceMemId,
    int? targetMemId,
    Condition? condition,
  }) =>
      v(
        () async => await ship(
          condition: And([
            if (sourceMemId != null)
              Equals(defFkMemRelationsSourceMemId, sourceMemId),
            if (targetMemId != null)
              Equals(defFkMemRelationsTargetMemId, targetMemId),
            if (condition != null) condition,
          ]),
        ).then((v) => Future.wait(v.map((e) => unarchive(e)))),
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
