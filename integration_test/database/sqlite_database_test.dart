@TestOn('android || windows')
import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/sqlite_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  const pkName = 'id';
  const textFieldName = 'text';
  const datetimeFieldName = 'datetime';

  const dbName = 'test_sqlite.db';
  const dbVersion = 1;
  final testTable = DefT(
    tableName,
    [
      DefPK(pkName, TypeF.integer, autoincrement: true),
      DefF(textFieldName, TypeF.text),
      DefF(datetimeFieldName, TypeF.datetime),
    ],
  );
  final tables = [testTable];

  tearDown(() async {
    await SqliteDatabase(dbName, dbVersion, tables).delete();
  });

  test(
    'Open and delete database',
    () async {
      final database = SqliteDatabase(dbName, dbVersion, tables);

      expect(database.name, dbName);
      expect(database.version, dbVersion);
      expect(database.tables, tables);

      final deleteResult = await database.delete();
      expect(deleteResult, false);

      final openedDb = await database.open();
      expect(openedDb, database);

      final deleteResultSuccess = await database.delete();
      expect(deleteResultSuccess, true);
    },
  );

  test(
    'Basic operation.',
    () async {
      final database = await SqliteDatabase(dbName, dbVersion, tables).open();

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

      final deletedCount = await database.deleteAll(testTable);
      expect(deletedCount, 1);
    },
  );
}
