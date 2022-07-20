import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/indexed_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  const pkName = 'id';
  const textFieldName = 'text';

  const dbName = 'test_indexed_db.db';
  const dbVersion = 1;
  final testTable = DefT(
    tableName,
    [
      DefPK(pkName, TypeF.integer, autoincrement: true),
      DefF(textFieldName, TypeF.integer),
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
      expect(deleteResult, true);

      final openedDb = await database.open();
      expect(openedDb, database);

      final deleteResultSuccess = await database.delete();
      expect(deleteResultSuccess, true);
    },
  );

  test(
    'Basic operation.',
    () async {
      final database = await IndexedDatabase(dbName, dbVersion, tables).open();

      const text = 'test text';
      final inserted = await database.insert(testTable, {textFieldName: text});
      expect(inserted, 1);
      const text2 = 'test text 2';
      final inserted2 =
          await database.insert(testTable, {textFieldName: text2});
      expect(inserted2, 2);

      final selected = await database.select(testTable);
      expect(selected, [
        {pkName: inserted, textFieldName: text},
        {pkName: inserted2, textFieldName: text2},
      ]);

      const updatedText = 'updated text';
      final updated = await database.updateById(
        testTable,
        {textFieldName: updatedText},
        inserted,
      );
      expect(updated, 1);

      final selectedById = await database.selectById(testTable, inserted);
      expect(selectedById, {pkName: inserted, textFieldName: updatedText});

      final deleted = await database.deleteById(testTable, inserted);
      expect(deleted, 1);

      final selectedWithoutDeleted = await database.select(testTable);
      expect(selectedWithoutDeleted, [
        {pkName: inserted2, textFieldName: text2},
      ]);
    },
  );
}
