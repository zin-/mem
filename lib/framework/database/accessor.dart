import 'package:mem/framework/database/definition/table_definition_v2.dart';
import 'package:mem/logger/log_service.dart';
import 'package:sqflite/sqlite_api.dart';

// ISSUE #209
//  TODO implement select
//  TODO implement update
//  TODO implement delete
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

  DatabaseAccessor(this._nativeDatabase);
}
