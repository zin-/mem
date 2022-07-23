import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  const pkName = 'id';
  const textFieldName = 'text';
  const datetimeFieldName = 'datetime';

  const dbName = 'test.db';
  const dbVersion = 1;
  final testTable = DefTV2(
    tableName,
    [
      DefPKV2(pkName, TypeCV2.integer, autoincrement: true),
      DefC(textFieldName, TypeCV2.integer),
      DefC(datetimeFieldName, TypeCV2.datetime),
    ],
  );
  final tableDefinitions = [testTable];
  DatabaseV2 database;

  tearDown(() async {
    await DatabaseManager.delete(dbName);
  });

  test(
    'insert',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final inserted = await table.insert({
        textFieldName: 'test text',
        datetimeFieldName: DateTime.now(),
      });
      expect(inserted, 1);
    },
  );

  test(
    'select',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final datetime = DateTime.now();
      final test1 = {
        textFieldName: 'test text 1',
        datetimeFieldName: datetime,
      };
      final inserted1 = await table.insert(test1);
      final test2 = {
        textFieldName: 'test text 2',
        datetimeFieldName: datetime,
      };
      final inserted2 = await table.insert(test2);

      final selected = await table.select();
      expect(selected.length, 2);
      expect(selected, [
        test1..putIfAbsent(pkName, () => inserted1),
        test2..putIfAbsent(pkName, () => inserted2),
      ]);
    },
  );

  test(
    'selectByPk',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final datetime = DateTime.now();
      final test = {
        textFieldName: 'test text',
        datetimeFieldName: datetime,
      };
      final inserted = await table.insert(test);

      final selectedById = await table.selectByPk(inserted);
      expect(
        selectedById,
        test..putIfAbsent(pkName, () => inserted),
      );
    },
  );

  test(
    'updateByPk',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final datetime = DateTime.now();
      final test = {
        textFieldName: 'test text',
        datetimeFieldName: datetime,
      };
      final inserted = await table.insert(test);

      const updateText = 'update text';
      final updatedByPk = await table.updateByPk(
        inserted,
        test..update(textFieldName, (value) => updateText),
      );
      expect(updatedByPk, 1);

      final selectedById = await table.selectByPk(inserted);
      expect(
        selectedById,
        test
          ..putIfAbsent(pkName, () => inserted)
          ..update(textFieldName, (value) => updateText),
      );
    },
  );

  test(
    'deleteById',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final datetime = DateTime.now();
      final test = {
        textFieldName: 'test text',
        datetimeFieldName: datetime,
      };
      final inserted = await table.insert(test);
      await table.insert({
        textFieldName: 'test text 2',
        datetimeFieldName: datetime,
      });

      final deletedByPk = await table.deleteByPk(inserted);
      expect(deletedByPk, 1);

      final selected = await table.select();
      expect(selected.length, 1);
    },
  );

  test(
    'deleteAll',
    () async {
      database = await DatabaseManager.open(DefD(
        dbName,
        dbVersion,
        tableDefinitions,
      ));
      final table = database.getTable(tableName);

      final datetime = DateTime.now();
      final test = {
        textFieldName: 'test text',
        datetimeFieldName: datetime,
      };
      await table.insert(test);
      await table.insert({
        textFieldName: 'test text 2',
        datetimeFieldName: datetime,
      });

      final deletedByPk = await table.delete();
      expect(deletedByPk, 2);

      final selected = await table.select();
      expect(selected.length, 0);
    },
  );
}
