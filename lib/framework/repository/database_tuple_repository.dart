import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/database.dart';
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

abstract class DatabaseTupleRepository<ENTITY extends Entity,
    SAVED extends DatabaseTupleEntity> extends Repository<ENTITY> {
  static final driftDatabase = AppDatabase();

  static DatabaseAccessor? _databaseAccessor;
  static final Map<TableDefinition, Repository> _repositories = {};

  final DatabaseDefinition _databaseDefinition;
  final TableDefinition _tableDefinition;

  // FIXME DatabaseDefinitionの中にTableDefinitionがあるのでEから取得できるのでは？
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
        () async {
          final fromNative = (await (await _dbA).select(
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
              .toList();
          // debug("fromNative(${_tableDefinition.name}): $fromNative");

          final tableInfo = getTableInfo(_tableDefinition);
          final query = driftDatabase.select(tableInfo);

          if (condition != null) {
            final driftExpression = condition.toDriftExpression(tableInfo);
            if (driftExpression != null) {
              query.where((tbl) => driftExpression);
            }
          }

          // TODO: groupBy support for drift
          // if (groupBy != null) {
          //   final columns = groupBy.columns
          //       .map((colDef) => _getColumn(tableInfo, colDef.name))
          //       .whereType<drift.GeneratedColumn>()
          //       .toList();
          //   if (columns.isNotEmpty) {
          //     query.groupBy((tbl) => columns);
          //   }
          // }

          if (orderBy != null && orderBy.isNotEmpty) {
            query.orderBy(
              orderBy
                  .map((orderByItem) => _toOrderClauseGenerator(
                        tableInfo,
                        orderByItem,
                      ))
                  .whereType<drift.OrderClauseGenerator>()
                  .toList(),
            );
          }

          if (limit != null || offset != null) {
            query.limit(limit ?? 999999999, offset: offset ?? 0);
          }

          final fromDrift = (await query.get()).map((e) {
            final Map<String, dynamic> jsonMap = (e).toJson(
                serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ));

            final converted = Map.fromEntries(jsonMap.entries.map((e) {
              try {
                return MapEntry(e.key, DateTime.parse(e.value as String));
              } catch (erorr) {
                return MapEntry(e.key, e.value);
              }
            }));

            return pack(converted);
          }).toList();
          // debug("fromDrift(${_tableDefinition.name}}: $fromDrift");

          warn(
            "same?(${_tableDefinition.name}): ${fromNative.map((e) => e.value).toString() == fromDrift.map((e) => e.value).toString()}",
          );
          return fromNative;
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

  drift.TableInfo getTableInfo(TableDefinition tableDefinition) =>
      driftDatabase.allTables
          .firstWhere((e) => e.actualTableName == tableDefinition.name);

  drift.GeneratedColumn? _getColumn(
      drift.TableInfo tableInfo, String columnName) {
    try {
      final table = tableInfo as dynamic;
      final columns = table.$columns as List<drift.GeneratedColumn>;
      final column = columns.firstWhere(
        (col) {
          final actualName = _getColumnName(col);
          return actualName == columnName ||
              actualName == _toSnakeCase(columnName);
        },
        orElse: () => throw StateError('Column not found: $columnName'),
      );
      return column;
    } catch (e) {
      return null;
    }
  }

  String _getColumnName(drift.GeneratedColumn column) {
    try {
      final col = column as dynamic;
      return col.name as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  drift.OrderClauseGenerator? _toOrderClauseGenerator(
      drift.TableInfo tableInfo, OrderBy orderBy) {
    final column = _getColumn(tableInfo, orderBy.columnDefinition.name);
    if (column == null) return null;

    return (tbl) {
      if (orderBy is Descending) {
        return drift.OrderingTerm(
          expression: column,
          mode: drift.OrderingMode.desc,
        );
      } else {
        return drift.OrderingTerm(
          expression: column,
          mode: drift.OrderingMode.asc,
        );
      }
    };
  }
}
