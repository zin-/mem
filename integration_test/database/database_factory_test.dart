import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';

import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  final dbDef = DefD('test.db', 1, [
    DefT(tableName, [DefPK('id', ColumnType.integer)])
  ]);
  tearDown(() async => await DatabaseManager().delete(dbDef.name));

  test(
    'Open database twice.',
    () async {
      final db = await DatabaseManager().open(dbDef);
      if (kIsWeb) {
        expect(db, isA<IndexedDatabase>());
      } else {
        expect(db, isA<SqliteDatabase>());
      }

      final openedDb = await DatabaseManager().open(dbDef);
      expect(openedDb, db);
    },
  );

  test(
    'Open and close database.',
    () async {
      const tName = 'tests';
      final db = await DatabaseManager().open(dbDef);
      final table = db.getTable(tName);

      final closeResult1 = await DatabaseManager().close(dbDef.name);
      expect(closeResult1, true);
      final closeResult2 = await DatabaseManager().close(dbDef.name);
      expect(closeResult2, false);

      final directCloseResult = await db.close();
      expect(directCloseResult, false);

      expect(
        () => table.insert({}),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.select(),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.selectByPk(1),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.updateByPk(1, {}),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.delete(),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.deleteByPk(1),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
    },
  );

  test(
    'Open and delete database.',
    () async {
      final db = await DatabaseManager().open(dbDef);
      final table = db.getTable(tableName);

      final deleteResult1 = await DatabaseManager().delete(dbDef.name);
      expect(deleteResult1, true);
      final deleteResult2 = await DatabaseManager().delete(dbDef.name);
      expect(deleteResult2, false);

      final directDeleteResult = await db.delete();
      expect(directDeleteResult, false);

      expect(
        () => table.insert({}),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.select(),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.selectByPk(1),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.updateByPk(1, {}),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.delete(),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
      expect(
        () => table.deleteByPk(1),
        throwsA((e) => e is DatabaseDoesNotExistException),
      );
    },
  );
}
