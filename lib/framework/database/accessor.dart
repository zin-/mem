import 'package:mem/logger/log_service.dart';
import 'package:sqflite/sqlite_api.dart';

// ISSUE #209
class DatabaseAccessor {
  final Database _nativeDatabase;

  @Deprecated("Use only for developing or test.")
  Database get nativeDatabase => _nativeDatabase;

  Future<bool> isOpened() => v(
        () async {
          if (_nativeDatabase.isOpen) {
            try {
              return await _nativeDatabase.getVersion().then((value) => true);
            } on DatabaseException catch (e) {
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
                rethrow;
              }
            }
          }
          return false;
        },
      );

  DatabaseAccessor(this._nativeDatabase);
}
