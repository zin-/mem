import 'package:mem/logger/log_service.dart';
import 'package:sqflite/sqlite_api.dart';

import 'converter.dart';
import 'definition/table_definition_v2.dart';

class DatabaseAccessor {
  final Database _nativeDatabase;
  final DatabaseConverter _converter = DatabaseConverter();

  @Deprecated("Use only for developing or test.")
  Database get nativeDatabase => _nativeDatabase;

  Future<bool> isOpened() => v(
        () async =>
            _nativeDatabase.isOpen &&
            await _nativeDatabase.getVersion().then((value) => true).catchError(
              (e, stackTrace) async {
                final exceptionMessage = e.toString();
                // nativeDatabaseがcloseされずにdeleteされた場合に以下のエラーになる
                if (exceptionMessage.startsWith(
                      "DatabaseException(database_closed ",
                    ) ||
                    exceptionMessage.startsWith(
                      "SqfliteFfiException(error, Bad state: This database has already been closed})",
                    )) {
                  warn(e);
                  await _nativeDatabase.close();
                } else {
                  throw e;
                }
                return false;
              },
            ),
      );

  Future<int> insert(
    TableDefinitionV2 tableDefinition,
    Map<String, Object?> values,
  ) =>
      v(
        () => _nativeDatabase.insert(
          tableDefinition.name,
          _converter.to(values, tableDefinition),
        ),
        [tableDefinition, values],
      );

  Future<List<Map<String, Object?>>> select(
    TableDefinitionV2 tableDefinition, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) =>
      v(
        () => _nativeDatabase
            .query(
              tableDefinition.name,
              where: where,
              whereArgs: whereArgs,
              orderBy: orderBy,
              limit: limit,
            )
            .then((value) =>
                value.map((e) => _converter.from(e, tableDefinition)).toList()),
        [
          tableDefinition,
          where,
          whereArgs,
          orderBy,
          limit,
        ],
      );

  Future<int> update(
    TableDefinitionV2 tableDefinition,
    Map<String, Object?> value, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        () => _nativeDatabase.update(
          tableDefinition.name,
          _converter.to(value, tableDefinition),
          where: where,
          whereArgs: whereArgs,
        ),
        [
          tableDefinition,
          value,
          where,
          whereArgs,
        ],
      );

  Future<int> delete(
    TableDefinitionV2 tableDefinition, {
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        () => _nativeDatabase.delete(
          tableDefinition.name,
          where: where,
          whereArgs: whereArgs,
        ),
        [
          tableDefinition,
          where,
          whereArgs,
        ],
      );

  DatabaseAccessor(this._nativeDatabase);
}
