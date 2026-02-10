import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/database.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem.dart' as mem_domain;
import 'package:mem/features/mems/mem_entity.dart' as mem_entity;
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';

import 'definition/table_definition.dart';

Object? _valueFromMap(Map<String, Object?> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null) return v;
  }
  return null;
}

const _driftToTableDefKey = {
  'memId': 'mems_id',
  'sourceMemId': 'source_mems_id',
  'targetMemId': 'target_mems_id',
  'startIsAllDay': 'start_is_all_day',
  'endIsAllDay': 'end_is_all_day',
  'timeOfDaySeconds': 'time_of_day_seconds',
  'pausedAt': 'paused_at',
};

Map<String, Object?> _driftRowToEntityMap(dynamic row, String tableName) {
  final json = (row as dynamic).toJson(
    serializer: drift.ValueSerializer.defaults(
      serializeDateTimeValuesAsString: true,
    ),
  ) as Map<String, dynamic>;
  return Map.fromEntries(json.entries.map((e) {
    final key = _driftToTableDefKey[e.key] ?? e.key;
    Object? value = e.value;
    if (value is String) {
      try {
        value = DateTime.parse(value);
      } catch (_) {}
    }
    return MapEntry(key, value);
  }));
}

const _tableDefToDriftKey = {
  'mems_id': 'memId',
  'source_mems_id': 'sourceMemId',
  'target_mems_id': 'targetMemId',
};

class DriftDatabaseAccessor {
  final AppDatabase driftDatabase;

  DriftDatabaseAccessor._(this.driftDatabase);

  Future<int> count(
    TableDefinition tableDefinition, {
    Condition? condition,
  }) =>
      v(
        () async {
          try {
            final tableInfo = _getTableInfo(tableDefinition);
            var query = driftDatabase.select(tableInfo);
            if (condition != null) {
              final exp = condition.toDriftExpression(tableInfo);
              if (exp != null) query = query..where((_) => exp);
            }
            return (await query.get()).length;
          } catch (_) {
            return 0;
          }
        },
        {'tableDefinition': tableDefinition, 'condition': condition},
      );

  select(
    TableDefinition tableDefinition, {
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async {
          final drift.TableInfo tableInfo;
          try {
            tableInfo = _getTableInfo(tableDefinition);
          } catch (e) {
            return <Map<String, dynamic>>[];
          }
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
                  .map((orderByItem) => _toOrderClauseGenerator(
                        tableInfo,
                        orderByItem,
                      ))
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

          return rows
              .map((r) => _driftRowToEntityMap(r, tableDefinition.name))
              .toList();
        },
        {
          'tableDefinition': tableDefinition,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  insert(
    TableDefinition tableDefinition,
    Map<String, Object?> values,
  ) =>
      v(
        () async {
          final drift.TableInfo tableInfo;
          try {
            tableInfo = _getTableInfo(tableDefinition);
          } catch (e) {
            return 0;
          }
          final insertable = _createCompanionForTable(
            tableDefinition.name,
            values,
          );
          return await driftDatabase.into(tableInfo).insert(insertable);
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

          return await driftDatabase
              .into(tableInfo)
              .insertReturning(insertable);
        },
        {'domain': domain},
      );

  update(
    TableDefinition tableDefinition,
    Map<String, Object?> values,
  ) =>
      v(
        () async {
          final drift.TableInfo tableInfo;
          try {
            tableInfo = _getTableInfo(tableDefinition);
          } catch (e) {
            return 0;
          }

          final query = driftDatabase.update(tableInfo)
            ..where((t) => (t as dynamic).id.equals(values['id']));

          return await query.write(_createCompanionForTable(
            tableDefinition.name,
            values,
          ));
        },
      );

  Future updateV2(dynamic entity, {DateTime? updatedAt}) => v(
        () async {
          final query = driftDatabase.update(_getTableInfoV2(entity))
            ..where((t) => (t as dynamic).id.equals(entity.id));

          final updateable =
              convertIntoDriftUpdateable(entity, updatedAt: updatedAt);

          return (await query.writeReturning(updateable)).first;
        },
        {'entity': entity},
      );

  delete(
    TableDefinition tableDefinition,
    Condition? condition,
  ) =>
      v(
        () async {
          final drift.TableInfo tableInfo;
          try {
            tableInfo = _getTableInfo(tableDefinition);
          } catch (e) {
            return 0;
          }

          final query = driftDatabase.delete(tableInfo);

          if (condition != null) {
            final driftExpression = condition.toDriftExpression(tableInfo);
            if (driftExpression != null) {
              query.where((tbl) => driftExpression);
            }
          }

          return await query.go();
        },
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

          return await query.goAndReturn();
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

      case List<SavedActEntityV1> _:
        return driftDatabase.acts;

      default:
        throw StateError('Unknown domain: ${domain.runtimeType}');
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

  dynamic _createCompanionForTable(
    String tableName,
    Map<String, Object?> values,
  ) {
    T? val<T>(List<String> keys) => _valueFromMap(values, keys) as T?;

    switch (tableName) {
      case 'mems':
        return MemsCompanion.insert(
          name: values['name'] as String,
          doneAt: drift.Value(values['doneAt'] as DateTime?),
          notifyOn: drift.Value(values['notifyOn'] as DateTime?),
          notifyAt: drift.Value(values['notifyAt'] as DateTime?),
          endOn: drift.Value(values['endOn'] as DateTime?),
          endAt: drift.Value(values['endAt'] as DateTime?),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      case 'mem_items':
        return MemItemsCompanion.insert(
          type: values['type'] as String,
          value: values['value'] as String,
          memId: (val<int>(['mems_id', 'memId']) ?? 0),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      case 'acts':
        return ActsCompanion.insert(
          start: drift.Value(values['start'] as DateTime?),
          startIsAllDay:
              drift.Value(val<bool>(['start_is_all_day', 'startIsAllDay'])),
          end: drift.Value(values['end'] as DateTime?),
          endIsAllDay:
              drift.Value(val<bool>(['end_is_all_day', 'endIsAllDay'])),
          pausedAt: drift.Value(val<DateTime>(['paused_at', 'pausedAt'])),
          memId: (val<int>(['mems_id', 'memId']) ?? 0),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      case 'mem_repeated_notifications':
        return MemRepeatedNotificationsCompanion.insert(
          timeOfDaySeconds:
              (val<int>(['time_of_day_seconds', 'timeOfDaySeconds']) ?? 0),
          type: values['type'] as String,
          message: values['message'] as String,
          memId: (val<int>(['mems_id', 'memId']) ?? 0),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      case 'targets':
        return TargetsCompanion.insert(
          type: values['type'] as String,
          unit: values['unit'] as String,
          value: (values['value'] as int?) ?? 0,
          period: values['period'] as String,
          memId: (val<int>(['mems_id', 'memId']) ?? 0),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      case 'mem_relations':
        return MemRelationsCompanion.insert(
          sourceMemId: (val<int>(['source_mems_id', 'sourceMemId']) ?? 0),
          targetMemId: (val<int>(['target_mems_id', 'targetMemId']) ?? 0),
          type: values['type'] as String,
          value: drift.Value(values['value'] as int?),
          createdAt: values['createdAt'] as DateTime,
          updatedAt: drift.Value(values['updatedAt'] as DateTime?),
          archivedAt: drift.Value(values['archivedAt'] as DateTime?),
        );
      default:
        throw StateError('Unknown table: $tableName');
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
    default:
      throw StateError('Unknown domain: ${domain.runtimeType}');
  }
}

convertIntoDriftUpdateable(dynamic entity, {DateTime? updatedAt}) {
  switch (entity) {
    case mem_entity.MemEntity _:
      return convertIntoMemsUpdateable(entity, updatedAt: updatedAt);
    default:
      throw StateError('Unknown entity: ${entity.runtimeType}');
  }
}
