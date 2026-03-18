import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/database.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem.dart' as mem_domain;
import 'package:mem/features/mems/mem_entity.dart' as mem_entity;
import 'package:mem/features/mem_items/mem_item.dart' as mem_item_domain;
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_relations/mem_relation.dart'
    as mem_relation_domain;
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/features/targets/target.dart' as target_domain;

import 'definition/table_definition.dart';

const _tableDefToDriftKey = {
  'mems_id': 'memId',
  'source_mems_id': 'sourceMemId',
  'target_mems_id': 'targetMemId',
};

const _loadChildInChunkSize = 900;

class DriftDatabaseAccessor {
  final AppDatabase driftDatabase;

  DriftDatabaseAccessor._(this.driftDatabase);

  factory DriftDatabaseAccessor.withDatabase(AppDatabase database) =>
      DriftDatabaseAccessor._(database);

  Future<int> count(
    TableDefinition tableDefinition, {
    Condition? condition,
  }) =>
      v(
        () async {
          try {
            final tableInfo = _getTableInfo(tableDefinition);
            final countExpr = drift.countAll();
            final query = driftDatabase.selectOnly(tableInfo)..addColumns([countExpr]);
            if (condition != null) {
              final exp = condition.toDriftExpression(tableInfo);
              if (exp != null) query.where(exp);
            }
            final row = await query.getSingle();
            return row.read(countExpr) ?? 0;
          } catch (_) {
            return 0;
          }
        },
        {'tableDefinition': tableDefinition, 'condition': condition},
      );

  Future<List<dynamic>> selectV2(
    TableDefinition tableDefinition, {
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    List<LoadChildSpec>? loadChildren,
  }) =>
      v(
        () async {
          final tableInfo = _getTableInfoV2(tableDefinition);
          final query = driftDatabase.select(tableInfo);

          if (condition != null) {
            final driftExpression = condition.toDriftExpression(tableInfo);
            if (driftExpression != null) {
              query.where((tbl) => driftExpression);
            }
          }

          final hasGroupByWithExtra = groupBy?.extraColumns != null &&
              groupBy!.extraColumns!.isNotEmpty;
          final effectiveOrderBy = [
            if (hasGroupByWithExtra)
              for (final e in groupBy.extraColumns!) Descending(e.column),
            ...?orderBy,
          ];

          if (effectiveOrderBy.isNotEmpty) {
            query.orderBy(
              effectiveOrderBy
                  .map((orderByItem) =>
                      _toOrderClauseGenerator(tableInfo, orderByItem))
                  .whereType<drift.OrderClauseGenerator>()
                  .toList(),
            );
          }

          if (limit != null || offset != null) {
            if (hasGroupByWithExtra) {
              query.limit(100000, offset: 0);
            } else {
              query.limit(limit ?? 999999999, offset: offset ?? 0);
            }
          }

          var rows = await query.get();
          if (hasGroupByWithExtra && groupBy.columns.isNotEmpty) {
            final seen = <Object?, dynamic>{};
            final keyCol = groupBy.columns.first.name;
            final driftKey = _tableDefToDriftKey[keyCol] ?? keyCol;
            for (final r in rows) {
              final k = (r as dynamic).toJson()[driftKey];
              if (!seen.containsKey(k)) seen[k] = r;
            }
            rows = seen.values.toList();
            rows = rows.skip(offset ?? 0).take(limit ?? 999999999).toList();
          }

          if (loadChildren?.isNotEmpty == true && !hasGroupByWithExtra) {
            final specs = loadChildren!;
            final usedKeys = <String>{};
            for (final s in specs) {
              if (!usedKeys.add(s.resultKey)) {
                throw ArgumentError(
                  'Duplicate loadChildren.resultKey: ${s.resultKey}',
                );
              }
            }
            final parentIds =
                rows.map((r) => (r as dynamic).id as int).toSet();
            final childrenByParentId = <int, Map<String, List<dynamic>>>{};
            for (final id in parentIds) {
              childrenByParentId[id] = {};
            }
            for (final spec in specs) {
              final fk = LoadChildSpec.resolveFkToParent(
                spec.table,
                tableDefinition,
                spec.fkToParent,
              );
              final grouped =
                  await _loadChildRowsGrouped(spec, fk, parentIds);
              for (final e in grouped.entries) {
                childrenByParentId[e.key]![spec.resultKey] = e.value;
              }
            }
            return rows
                .map(
                  (row) => _convertToEntity(
                    row,
                    tableInfo.actualTableName,
                    children:
                        childrenByParentId[(row as dynamic).id as int] ?? {},
                  ),
                )
                .toList();
          }

          return rows
              .map((row) => _convertToEntity(row, tableInfo.actualTableName))
              .toList();
        },
        {
          'tableDefinition': tableDefinition,
          'condition': condition,
          'groupBy': groupBy,
          'loadChildren': loadChildren,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future insertV2(
    dynamic domain,
// TODO createdAtを受け取るべきかも
  ) =>
      v(
        () async {
          final tableInfo = _getTableInfoV2(domain);
          final insertable = convertIntoDriftInsertable(domain);

          final inserted =
              await driftDatabase.into(tableInfo).insertReturning(insertable);
          return _convertToEntity(inserted, tableInfo.actualTableName);
        },
        {'domain': domain},
      );

  Future updateV2(dynamic entity) => v(
        () async {
          final tableInfo = _getTableInfoV2(entity);
          final query = driftDatabase.update(tableInfo)
            ..where((t) => (t as dynamic).id.equals(entity.id));

          final updateable = convertIntoDriftUpdateable(entity);
          final updated = (await query.writeReturning(updateable)).first;
          return _convertToEntity(updated, tableInfo.actualTableName);
        },
        {'entity': entity},
      );

  Future<List<dynamic>> deleteV2(dynamic domain, {Condition? condition}) => v(
        () async {
          final tableInfo = _getTableInfoV2(domain);

          final query = driftDatabase.delete(tableInfo);

          if (domain is Mem || domain is MemEntity) {
            query.where((t) => (t as dynamic).id.equals(domain.id));
          }

          if (condition != null) {
            final driftExpression = condition.toDriftExpression(tableInfo);
            if (driftExpression != null) {
              query.where((tbl) => driftExpression);
            }
          }

          final deleted = await query.goAndReturn();
          final tableName = tableInfo.actualTableName;
          return deleted
              .map((row) => _convertToEntity(row, tableName))
              .toList();
        },
        {
          'domain': domain,
          'condition': condition,
        },
      );

  drift.TableInfo _getTableInfo(
    TableDefinition tableDefinition,
  ) =>
      driftDatabase.allTables
          .firstWhere((e) => e.actualTableName == tableDefinition.name);

  drift.TableInfo _getTableInfoV2(dynamic domain) {
    switch (domain) {
      case mem_domain.Mem _:
      case mem_entity.MemEntity _:
        return driftDatabase.mems;

      case mem_item_domain.MemItem _:
      case MemItemEntity _:
        return driftDatabase.memItems;

      case ActiveAct _:
      case FinishedAct _:
      case PausedAct _:
      case ActEntity _:
      case List<SavedActEntityV1> _:
        return driftDatabase.acts;

      case MemNotification _:
      case MemNotificationEntity _:
        return driftDatabase.memRepeatedNotifications;

      case target_domain.Target _:
      case TargetEntity _:
        return driftDatabase.targets;

      case mem_relation_domain.MemRelation _:
      case MemRelationEntity _:
        return driftDatabase.memRelations;

      case TableDefinition _:
        return driftDatabase.allTables.firstWhere(
          (e) => e.actualTableName == domain.name,
        );

      default:
        throw StateError('Unknown domain: ${domain.runtimeType}');
    }
  }

  Future<Map<int, List<dynamic>>> _loadChildRowsGrouped(
    LoadChildSpec spec,
    ForeignKeyDefinition fk,
    Set<int> parentIds,
  ) async {
    final childInfo = _getTableInfoV2(spec.table);
    final out = <int, List<dynamic>>{};
    if (parentIds.isEmpty) return out;
    final list = parentIds.toList();
    for (var i = 0; i < list.length; i += _loadChildInChunkSize) {
      final end = math.min(i + _loadChildInChunkSize, list.length);
      final chunk = list.sublist(i, end);
      final rows = await _selectChildChunk(childInfo, fk, chunk, spec.condition);
      for (final row in rows) {
        final pid = _parentIdFromChildRow(row, fk);
        out.putIfAbsent(pid, () => []).add(row);
      }
    }
    return out;
  }

  Future<List<dynamic>> _selectChildChunk(
    drift.TableInfo childInfo,
    ForeignKeyDefinition fk,
    List<int> parentIdsChunk,
    Condition? condition,
  ) async {
    final name = childInfo.actualTableName;
    switch (name) {
      case 'mem_items':
        var q = driftDatabase.select(driftDatabase.memItems);
        q.where((t) => t.memId.isIn(parentIdsChunk));
        if (condition != null) {
          final exp = condition.toDriftExpression(childInfo);
          if (exp != null) q.where((t) => exp);
        }
        return await q.get();
      case 'mem_repeated_notifications':
        var q = driftDatabase.select(driftDatabase.memRepeatedNotifications);
        q.where((t) => t.memId.isIn(parentIdsChunk));
        if (condition != null) {
          final exp = condition.toDriftExpression(childInfo);
          if (exp != null) q.where((t) => exp);
        }
        return await q.get();
      case 'acts':
        var q = driftDatabase.select(driftDatabase.acts);
        q.where((t) => t.memId.isIn(parentIdsChunk));
        if (condition != null) {
          final exp = condition.toDriftExpression(childInfo);
          if (exp != null) q.where((t) => exp);
        }
        return await q.get();
      case 'targets':
        var q = driftDatabase.select(driftDatabase.targets);
        q.where((t) => t.memId.isIn(parentIdsChunk));
        if (condition != null) {
          final exp = condition.toDriftExpression(childInfo);
          if (exp != null) q.where((t) => exp);
        }
        return await q.get();
      case 'mem_relations':
        if (fk.name == 'source_mems_id') {
          var q = driftDatabase.select(driftDatabase.memRelations);
          q.where((t) => t.sourceMemId.isIn(parentIdsChunk));
          if (condition != null) {
            final exp = condition.toDriftExpression(childInfo);
            if (exp != null) q.where((t) => exp);
          }
          return await q.get();
        }
        if (fk.name == 'target_mems_id') {
          var q = driftDatabase.select(driftDatabase.memRelations);
          q.where((t) => t.targetMemId.isIn(parentIdsChunk));
          if (condition != null) {
            final exp = condition.toDriftExpression(childInfo);
            if (exp != null) q.where((t) => exp);
          }
          return await q.get();
        }
        throw StateError(
          'mem_relations loadChildren requires fkToParent source_mems_id or target_mems_id',
        );
      default:
        throw StateError('loadChildren not supported for table: $name');
    }
  }

  int _parentIdFromChildRow(dynamic row, ForeignKeyDefinition fk) {
    switch (fk.name) {
      case 'mems_id':
        return row.memId as int;
      case 'source_mems_id':
        return row.sourceMemId as int;
      case 'target_mems_id':
        return row.targetMemId as int;
      default:
        throw StateError('Unsupported FK ${fk.name} for loadChildren');
    }
  }

  _convertToEntity(
    dynamic row,
    String tableName, {
    Map<String, dynamic> children = const {},
  }) {
    final childEntites = children.map((key, value) {
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) => _convertToEntity(e, key)).toList(),
        );
      } else {
        return MapEntry(key, _convertToEntity(value, key));
      }
    });

    switch (tableName) {
      case 'mems':
        return MemEntity.fromTuple(row, children: childEntites);
      case 'mem_items':
        return MemItemEntity.fromTuple(row);
      case 'mem_repeated_notifications':
        return MemNotificationEntity.fromTuple(row);
      case 'acts':
        return ActEntity.fromTuple(row);
      case 'targets':
        return TargetEntity.fromTuple(row);
      case 'mem_relations':
        return MemRelationEntity.fromTuple(row);

      default:
        throw StateError('Unknown table: $tableName');
    }
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

  String _getColumnName(drift.GeneratedColumn column) {
    try {
      final col = column as dynamic;
      return col.name as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  static const _tableDefToDriftColumn = {
    'mems_id': 'mem_id',
    'source_mems_id': 'source_mem_id',
    'target_mems_id': 'target_mem_id',
  };

  drift.GeneratedColumn? _getColumn(
      drift.TableInfo tableInfo, String columnName) {
    try {
      final table = tableInfo as dynamic;
      final columns = table.$columns as List<drift.GeneratedColumn>;
      final column = columns.firstWhere(
        (col) {
          final actualName = _getColumnName(col);
          return actualName == columnName ||
              actualName == toSnakeCase(columnName) ||
              (_tableDefToDriftColumn[columnName] != null &&
                  actualName == _tableDefToDriftColumn[columnName]);
        },
        orElse: () => throw StateError('Column not found: $columnName'),
      );
      return column;
    } catch (e) {
      return null;
    }
  }

  factory DriftDatabaseAccessor() =>
      Singleton.of(() => DriftDatabaseAccessor._(AppDatabase()));

  Future<void> close() async {
    await driftDatabase.close();
  }

  static void reset() {
    Singleton.reset<DriftDatabaseAccessor>();
  }
}

String toSnakeCase(String camelCase) {
  return camelCase.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

convertIntoDriftInsertable(dynamic domain) {
  switch (domain) {
    case mem_domain.Mem _:
      return convertIntoMemsInsertable(domain, DateTime.now());

    case mem_item_domain.MemItem _:
      return convertIntoMemItemsInsertable(domain, DateTime.now());

    case ActiveAct _:
    case FinishedAct _:
    case PausedAct _:
      return convertIntoActsInsertable(domain, createdAt: DateTime.now());

    case MemNotification _:
      return convertIntoMemRepeatedNotificationsInsertable(
        domain,
        createdAt: DateTime.now(),
      );

    case target_domain.Target _:
      return convertIntoTargetsInsertable(domain);

    case mem_relation_domain.MemRelation _:
      return convertIntoMemRelationsInsertable(domain);

    default:
      throw StateError('入力おかしいかも: ${domain.runtimeType}');
  }
}

convertIntoDriftUpdateable(
  dynamic entity,
) {
  switch (entity) {
    case mem_entity.MemEntity _:
      return convertIntoMemsUpdateable(entity);
    case MemItemEntity _:
      return convertIntoMemItemsUpdateable(entity);
    case ActEntity _:
      return convertIntoActsUpdateable(entity);
    case MemNotificationEntity _:
      return convertIntoMemRepeatedNotificationsUpdateable(entity);
    case TargetEntity _:
      return convertIntoTargetsUpdateable(entity);

    case MemRelationEntity _:
      return convertIntoMemRelationsUpdateable(entity);

    default:
      throw StateError('入力おかしいかも: ${entity.runtimeType}');
  }
}
