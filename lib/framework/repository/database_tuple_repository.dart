import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';

abstract class DatabaseTupleRepositoryV2<ENTITY extends Entity,
    SAVED extends DatabaseTupleEntity> extends Repository<ENTITY> {
  static DatabaseAccessor? _databaseAccessor;
  static final Map<TableDefinition, Repository> _repositories = {};

  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  // FIXME DatabaseDefinitionの中にTableDefinitionがあるのでEから取得できるのでは？
  DatabaseTupleRepositoryV2(this._databaseDefinition, this._tableDefinition) {
    _repositories[_tableDefinition] = this;

    childRepositories.updateAll(
      (childEntity, value) {
        final childTableDefinition = entityTableRelations[childEntity];
        if (childTableDefinition == null) {
          return value;
        } else {
          return value
            ..updateAll(
              (childRepository, value) {
                if (childRepository is DatabaseTupleRepositoryV2) {
                  return childTableDefinition.foreignKeyDefinitions.where(
                      (defFk) =>
                          defFk.parentTableDefinition == _tableDefinition);
                } else {
                  return value;
                }
              },
            );
        }
      },
    );
  }

  late final Future<DatabaseAccessor> _dbA = (() async => _databaseAccessor ??=
      await DatabaseRepository().receive(_databaseDefinition))();

  static Future close() => v(
        () async {
          await _databaseAccessor?.close();
          _databaseAccessor = null;
        },
      );

  Future<int> count({
    Condition? condition,
  }) =>
      v(
        () async => (await _dbA).count(
          _tableDefinition,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
        ),
        {
          'condition': condition,
        },
      );

  SAVED pack(Map<String, dynamic> map);

  Future<SAVED> receive(
    ENTITY entity, {
    DateTime? createdAt,
  }) =>
      v(
        () async {
          final entityMap = entity.toMap;

          entityMap[defColCreatedAt.name] = createdAt ?? DateTime.now();

          final id = await (await _dbA).insert(
            _tableDefinition,
            entityMap,
          );

          entityMap[defPkId.name] = id;

          return pack(entityMap);
        },
        {
          'entity': entity,
          'createdAt': createdAt,
        },
      );

  Future<List<SAVED>> ship({
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async => (await (await _dbA).select(
          _tableDefinition,
          groupBy: groupBy?.toQuery,
          extraColumns: groupBy?.toExtraColumns,
          where: condition?.where(),
          whereArgs: condition?.whereArgs(),
          orderBy: orderBy?.isEmpty != false
              ? null
              : orderBy?.map((e) => e.toQuery()).join(", "),
          offset: offset,
          limit: limit,
        ))
            .map((e) => pack(e))
            .toList(),
        {
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<SAVED> replace(
    SAVED savedEntity, {
    DateTime? updatedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;

          entityMap[defColUpdatedAt.name] = updatedAt ?? DateTime.now();

          final byId = Equals(defPkId, entityMap[defPkId.name]);
          await (await _dbA).update(
            _tableDefinition,
            entityMap,
            where: byId.where(),
            whereArgs: byId.whereArgs(),
          );

          return pack(entityMap);
        },
        {
          'savedEntity': savedEntity,
          'updatedAt': updatedAt,
        },
      );

  Future<SAVED> archive(
    SAVED savedEntity, {
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;

          entityMap[defColArchivedAt.name] = archivedAt ?? DateTime.now();

          final byId = Equals(defPkId, entityMap[defPkId.name]);
          await (await _dbA).update(
            _tableDefinition,
            entityMap,
            where: byId.where(),
            whereArgs: byId.whereArgs(),
          );

          return pack(entityMap);
        },
        {
          'savedEntity': savedEntity,
          'archivedAt': archivedAt,
        },
      );

  Future<SAVED> unarchive(
    SAVED savedEntity, {
    DateTime? updatedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;

          entityMap[defColUpdatedAt.name] = updatedAt ?? DateTime.now();
          entityMap[defColArchivedAt.name] = null;

          final byId = Equals(defPkId, entityMap[defPkId.name]);
          await (await _dbA).update(
            _tableDefinition,
            entityMap,
            where: byId.where(),
            whereArgs: byId.whereArgs(),
          );

          return pack(entityMap);
        },
        {
          'savedEntity': savedEntity,
          'updatedAt': updatedAt,
        },
      );

  @override
  Future<List<SAVED>> waste({
    Condition? condition,
  }) =>
      v(
        () async {
          final targets = await ship(
            condition: condition,
          );

          for (final byChild in childRepositories.entries) {
            for (final repositoryWithFks in byChild.value.entries) {
              if (repositoryWithFks.key != null &&
                  repositoryWithFks.value != null) {
                for (final fk in repositoryWithFks.value!) {
                  await repositoryWithFks.key!.waste(
                    condition: In(fk.name, targets.map((e) => e.id)),
                  );
                }
              }
            }
          }

          await _dbA.then(
            (dbA) async => await dbA.delete(
              _tableDefinition,
              where: condition?.where(),
              whereArgs: condition?.whereArgs(),
            ),
          );

          return targets;
        },
        {
          'condition': condition,
        },
      );
}
