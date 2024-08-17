import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/log_service.dart';

abstract class DatabaseTupleRepository<E extends Entity,
    Saved extends DatabaseTupleEntity> extends Repository<E> {
  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  // FIXME DatabaseDefinitionの中にTableDefinitionがあるのでEから取得できるのでは？
  DatabaseTupleRepository(this._databaseDefinition, this._tableDefinition);

  DatabaseAccessor? _databaseAccessor;

  late final Future<DatabaseAccessor> _dbA = (() async => _databaseAccessor ??=
      await DatabaseRepository().receive(_databaseDefinition))();

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

  Saved pack(Map<String, dynamic> map);

  Future<Saved> receive(E entity, {DateTime? createdAt}) => v(
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

  Future<List<Saved>> ship({
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

  Future<Saved> replace(Saved savedEntity, {DateTime? updatedAt}) => v(
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

  Future<Saved> archive(Saved savedEntity, {DateTime? archivedAt}) => v(
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

  Future<Saved> unarchive(Saved savedEntity, {DateTime? updatedAt}) => v(
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
}
