import 'package:mem/logger/log_service.dart';
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
              where: where,
              whereArgs: whereArgs?.map((e) => _converter.to(e)).toList(),
              orderBy: orderBy,
              offset: offset,
              limit: limit,
            )
            .then((value) =>
                value.map((e) => _converter.from(e, tableDefinition)).toList()),
        [
          tableDefinition.name,
          where,
          whereArgs,
          orderBy,
          limit,
        ],
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

  DatabaseAccessor(this._nativeDatabase);
}
