import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/database.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';
import 'package:sqflite/sqlite_api.dart';

import 'converter.dart';
import 'definition/table_definition.dart';

class DatabaseAccessor {
  final Database _nativeDatabase;
  final DatabaseConverter _converter = DatabaseConverter();

  @Deprecated("Use only for developing or test.")
  Database get nativeDatabase => _nativeDatabase;

  Future<int> insert(
    TableDefinition tableDefinition,
    Map<String, Object?> values,
  ) =>
      v(
        () => _nativeDatabase.insert(
          tableDefinition.name,
          values.map((key, value) => MapEntry(key, _converter.to(value))),
        ),
        [
          tableDefinition.name,
          values,
        ],
      );

  Future<int> count(
    TableDefinition tableDefinition, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        () async => (await _nativeDatabase.query(
          tableDefinition.name,
          columns: ["COUNT(*)"],
          where: where,
          whereArgs: whereArgs,
        ))[0]
            .values
            .elementAt(0) as int,
        {
          "tableDefinition": tableDefinition,
          "where": where,
          "whereArgs": whereArgs,
        },
      );

  Future<List<Map<String, Object?>>> select(
    TableDefinition tableDefinition, {
    String? groupBy,
    List<String>? extraColumns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () => _nativeDatabase
            .query(
              tableDefinition.name,
              columns: extraColumns == null ? null : ['*', ...extraColumns],
              where: where,
              whereArgs: whereArgs?.map((e) => _converter.to(e)).toList(),
              groupBy: groupBy,
              orderBy: orderBy,
              offset: offset,
              limit: limit,
            )
            .then((value) =>
                value.map((e) => _converter.from(e, tableDefinition)).toList()),
        {
          'tableName': tableDefinition.name,
          'groupBy': groupBy,
          'extraColumns': extraColumns,
          'where': where,
          'whereArgs': whereArgs,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<int> update(
    TableDefinition tableDefinition,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        () => _nativeDatabase.update(
          tableDefinition.name,
          values.map((key, value) => MapEntry(key, _converter.to(value))),
          where: where,
          whereArgs: whereArgs?.map((e) => _converter.to(e)).toList(),
        ),
        [
          tableDefinition.name,
          values,
          where,
          whereArgs,
        ],
      );

  Future<int> delete(
    TableDefinition tableDefinition, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        () => _nativeDatabase.delete(
          tableDefinition.name,
          where: where,
          whereArgs: whereArgs?.map((e) => _converter.to(e)).toList(),
        ),
        [
          tableDefinition.name,
          where,
          whereArgs,
        ],
      );

  Future<void> close() => v(
        () async => await _nativeDatabase.close(),
      );

  DatabaseAccessor(this._nativeDatabase);
}

class DriftDatabaseAccessor {
  final AppDatabase driftDatabase;

  DriftDatabaseAccessor._(this.driftDatabase);

  select(
    drift.TableInfo tableInfo, {
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () async {
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

          return await query.get();
        },
        {
          'tableInfo': tableInfo,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

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

  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  factory DriftDatabaseAccessor() =>
      Singleton.of(() => DriftDatabaseAccessor._(AppDatabase()));
}
