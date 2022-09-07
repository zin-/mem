@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

void main() {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
    );
  });
}
