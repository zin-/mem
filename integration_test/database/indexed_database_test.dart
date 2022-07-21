import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/indexed_database.dart';

// FIXME sqlite_database_testと同じ動作になることを保証するため、同じテストにする
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  const pkName = 'id';
  const textFieldName = 'text';
  const datetimeFieldName = 'datetime';

  const dbName = 'test_indexed_db.db';
  const dbVersion = 1;
  final testTable = DefT(
    tableName,
    [
      DefPK(pkName, TypeF.integer, autoincrement: true),
      DefF(textFieldName, TypeF.integer),
      DefF(datetimeFieldName, TypeF.datetime),
    ],
  );
  final tables = [testTable];

  tearDown(() async {
    await IndexedDatabase(dbName, dbVersion, tables).delete();
  });

  test(
    'Open and delete database',
    () async {
      final database = IndexedDatabase(dbName, dbVersion, tables);

      expect(database.name, dbName);
      expect(database.version, dbVersion);
      expect(database.tables, tables);

      final deleteResult = await database.delete();
      expect(deleteResult, false);

      final openedDb = await database.open();
      expect(openedDb, database);

      final deleteResultSuccess = await database.delete();
      // FIXME 真偽値が反転している？
      expect(deleteResultSuccess, false);
    },
  );

  test(
    'Basic operation.',
    () async {
      final database = await IndexedDatabase(dbName, dbVersion, tables).open();

      final nowDatetimeString = DateTime.now().toIso8601String();

      const text = 'test text';
      final inserted = await database.insert(testTable, {
        textFieldName: text,
        datetimeFieldName: nowDatetimeString,
      });
      expect(inserted, 1);
      const text2 = 'test text 2';
      final inserted2 = await database.insert(testTable, {
        textFieldName: text2,
        datetimeFieldName: nowDatetimeString,
      });
      expect(inserted2, 2);

      final selected = await database.select(testTable);
      expect(selected, [
        {
          pkName: inserted,
          textFieldName: text,
          datetimeFieldName: nowDatetimeString,
        },
        {
          pkName: inserted2,
          textFieldName: text2,
          datetimeFieldName: nowDatetimeString,
        },
      ]);

      const updatedText = 'updated text';
      final updated = await database.updateById(
        testTable,
        {
          textFieldName: updatedText,
          // FIXME sqlite_databaseと挙動が異なっている
          datetimeFieldName: nowDatetimeString,
        },
        inserted,
      );
      expect(updated, 1);

      final selectedById = await database.selectById(testTable, inserted);
      expect(selectedById, {
        pkName: inserted,
        textFieldName: updatedText,
        datetimeFieldName: nowDatetimeString,
      });

      final deleted = await database.deleteById(testTable, inserted);
      expect(deleted, 1);

      final selectedWithoutDeleted = await database.select(testTable);
      expect(selectedWithoutDeleted, [
        {
          pkName: inserted2,
          textFieldName: text2,
          datetimeFieldName: nowDatetimeString,
        },
      ]);
    },
  );
}
