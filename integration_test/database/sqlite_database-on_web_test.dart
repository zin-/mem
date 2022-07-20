@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/sqlite_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const dbName = 'test_sqlite.db';
  const dbVersion = 1;

  test(
    'Error on Chrome',
    () async {
      expect(
        () => SqliteDatabase(dbName, dbVersion, []),
        throwsA((e) => e is DatabaseException),
      );
    },
  );
}
