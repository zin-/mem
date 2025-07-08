import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';

class MemRelationRepository extends DatabaseTupleRepositoryV2<MemRelationEntity,
    SavedMemRelationEntity> {
  MemRelationRepository() : super(databaseDefinition, defTableMemRelations);

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
    int? sourceMemId,
    int? targetMemId,
    Condition? condition,
    DateTime? archivedAt,
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
        ).then((v) =>
            Future.wait(v.map((e) => archive(e, archivedAt: archivedAt)))),
        {
          'sourceMemId': sourceMemId,
          'targetMemId': targetMemId,
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
}
