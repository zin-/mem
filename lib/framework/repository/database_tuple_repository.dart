import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/repository.dart';
import 'package:mem/features/logger/log_service.dart';

abstract class DatabaseTupleRepository<
    ENTITYV1 extends EntityV1,
    SAVEDV1 extends DatabaseTupleEntityV1,
    DOMAIN,
    ID,
    ENTITY extends Entity<ID>> extends Repository<ENTITYV1, DOMAIN> {
  static final _driftAccessor = DriftDatabaseAccessor();
  static final Map<TableDefinition, Repository> _repositories = {};

  // ignore: unused_field
  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  DatabaseTupleRepository(this._databaseDefinition, this._tableDefinition) {
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
                if (childRepository is DatabaseTupleRepository) {
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

  static Future close() => v(
        () async {
          await DriftDatabaseAccessor().close();
          DriftDatabaseAccessor.reset();
        },
      );

  Future<int> count({
    Condition? condition,
  }) =>
      v(
        () async => _driftAccessor.count(
          _tableDefinition,
          condition: condition,
        ),
        {'condition': condition},
      );

  SAVEDV1 pack(Map<String, dynamic> map);
  ENTITY packV2(dynamic tuple) => throw UnimplementedError();
  convert(DOMAIN domain) => throw UnimplementedError();

  Future<SAVEDV1> receive(
    ENTITYV1 entity, {
    DateTime? createdAt,
  }) =>
      v(
        () async {
          final entityMap = entity.toMap;
          entityMap[defColCreatedAt.name] = createdAt ?? DateTime.now();

          final id = await _driftAccessor.insert(
            _tableDefinition,
            entityMap,
          );
          entityMap[defPkId.name] = id;

          return pack(entityMap);
        },
        {'entity': entity, 'createdAt': createdAt},
      );

  Future<ENTITY> receiveV2(DOMAIN domain) => v(
        () async {
          final inserted = await _driftAccessor.insertV2(domain);

          return packV2(inserted);
        },
        {'domain': domain},
      );

  Future<List<SAVEDV1>> ship({
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async {
          final rows = await _driftAccessor.select(
            _tableDefinition,
            condition: condition,
            groupBy: groupBy,
            orderBy: orderBy,
            offset: offset,
            limit: limit,
          );
          return rows
              .map<SAVEDV1>((e) => pack(e as Map<String, dynamic>))
              .toList();
        },
        {
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<SAVEDV1> replace(
    SAVEDV1 savedEntity, {
    DateTime? updatedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;
          entityMap[defColUpdatedAt.name] = updatedAt ?? DateTime.now();

          await _driftAccessor.update(
            _tableDefinition,
            entityMap,
          );

          return pack(entityMap);
        },
        {'savedEntity': savedEntity, 'updatedAt': updatedAt},
      );

  // TODO SAVEDを新しいEntityに置き換える
  Future<SAVEDV1> replaceV2(ENTITY entity) => v(
        () async {
          final updated = await _driftAccessor.updateV2(entity);

          return pack(updated.toJson());
        },
        {'entity': entity},
      );

  Future<SAVEDV1> archive(
    SAVEDV1 savedEntity, {
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;
          entityMap[defColArchivedAt.name] = archivedAt ?? DateTime.now();

          await _driftAccessor.update(
            _tableDefinition,
            entityMap,
          );

          return pack(entityMap);
        },
        {'savedEntity': savedEntity, 'archivedAt': archivedAt},
      );

  Future<SAVEDV1> unarchive(
    SAVEDV1 savedEntity, {
    DateTime? updatedAt,
  }) =>
      v(
        () async {
          final entityMap = savedEntity.toMap;
          entityMap[defColUpdatedAt.name] = updatedAt ?? DateTime.now();
          entityMap[defColArchivedAt.name] = null;

          await _driftAccessor.update(
            _tableDefinition,
            entityMap,
          );

          return pack(entityMap);
        },
        {'savedEntity': savedEntity, 'updatedAt': updatedAt},
      );

  @override
  Future<List<SAVEDV1>> waste({
    Condition? condition,
  }) =>
      v(
        () async {
          final targets = await ship(condition: condition);

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

          await _driftAccessor.delete(
            _tableDefinition,
            condition,
          );

          return targets;
        },
        {'condition': condition},
      );
}
