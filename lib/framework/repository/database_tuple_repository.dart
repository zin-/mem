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
    ENTITY extends EntityV1,
    SAVED extends DatabaseTupleEntityV1,
    DOMAIN> extends Repository<ENTITY, DOMAIN> {
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

  SAVED pack(Map<String, dynamic> map);
  packV2(dynamic domain) => throw UnimplementedError();
  convert(DOMAIN domain) => throw UnimplementedError();

  Future<SAVED> receive(
    ENTITY entity, {
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

  // TODO SAVEDを新しいEntityに置き換える
  Future<SAVED> receiveV2(DOMAIN domain) => v(
        () async {
          final inserted = await _driftAccessor.insertV2(domain);

          final saved = pack(inserted.toJson());
          // final saved = packV2(inserted);
          // debug('saved=$saved');

          return saved;
        },
        {'domain': domain},
      );

  Future<List<SAVED>> ship({
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
              .map<SAVED>((e) => pack(e as Map<String, dynamic>))
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

  Future<SAVED> replace(
    SAVED savedEntity, {
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

  Future<SAVED> archive(
    SAVED savedEntity, {
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

  Future<SAVED> unarchive(
    SAVED savedEntity, {
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
  Future<List<SAVED>> waste({
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
