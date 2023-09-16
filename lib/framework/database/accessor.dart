import 'package:mem/framework/database/definition/table_definition_v2.dart';
import 'package:mem/logger/log_service.dart';
import 'package:sqflite/sqlite_api.dart';

// ISSUE #209
class DatabaseAccessor {
  final Database _nativeDatabase;

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
    Map<String, Object?> value,
  ) =>
      v(
        () => _nativeDatabase.insert(tableDefinition.name, value),
        [tableDefinition, value],
      );

  Future<List<Map<String, Object?>>> select(
    TableDefinitionV2 tableDefinition, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) =>
      v(
        () => _nativeDatabase.query(
          tableDefinition.name,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
        ),
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
          value,
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
