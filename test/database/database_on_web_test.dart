@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';

void main() {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  const dbName = 'test_sqlite.db';
  const dbVersion = 1;

  group('Database on web', () {
    test(
      'SQLite database: Error on Chrome.',
      () async {
        expect(
          () => SqliteDatabase(DefD(dbName, dbVersion, [])),
          throwsA(
            (e) =>
                e is DatabaseException &&
                e.message == 'Unsupported platform. Platform: Web',
          ),
        );
      },
      tags: 'Medium',
    );

    test(
      'Indexed database: require at least 1 table.',
      () async {
        expect(
          () => IndexedDatabase(DefD(dbName, dbVersion, [])),
          throwsA(
            (e) =>
                e is DatabaseException &&
                e.message == 'Requires at least 1 table.',
          ),
        );
      },
      tags: 'Medium',
    );
  });
}
