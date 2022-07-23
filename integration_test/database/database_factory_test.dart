import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // FIXME delete
  // test(
  //   'Open database.',
  //   () async {
  //     const dbName = 'test.db';
  //     const dbVersion = 1;
  //
  //     final database = await DatabaseFactory.open(
  //       dbName,
  //       dbVersion,
  //       [],
  //     );
  //
  //     if (kIsWeb) {
  //       expect(database, const TypeMatcher<IndexedDatabase>());
  //     } else {
  //       expect(database, const TypeMatcher<SqliteDatabase>());
  //     }
  //   },
  // );

  test('Open and delete database.', () async {
    const dbName = 'test.db';
    final db = await DatabaseManager.open(DefD(dbName, 1, []));

    if (!kIsWeb) {
      expect(db, isA<SqliteDatabaseV2>());
    } else {
      expect(db, isA<IndexedDatabaseV2>());
    }

    final openedDb = await DatabaseManager.open(DefD(dbName, 1, []));
    expect(openedDb, db);

    await DatabaseManager.delete(dbName);
  });
}
