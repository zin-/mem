@TestOn('vm || android || windows')
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/definitions.dart';

void main() {
  Logger(level: Level.verbose);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const tableName = 'tests';
  const pkName = 'id';
  const textFieldName = 'text';
  const datetimeFieldName = 'datetime';
  final testTable = DefT(
    tableName,
    [
      DefPK(pkName, TypeC.integer, autoincrement: true),
      DefC(textFieldName, TypeC.integer),
      DefC(datetimeFieldName, TypeC.datetime),
    ],
  );
  final defD = DefD(
    'test.db',
    1,
    [testTable],
  );

  late SqliteDatabase sqliteDatabase;

  setUp(() async {
    sqliteDatabase = await SqliteDatabase(defD).open() as SqliteDatabase;
  });
  tearDown(() async {
    await sqliteDatabase.delete();
  });

  test(
    'insert',
    () async {
      final table = sqliteDatabase.getTable(tableName);

      final insertedId = await table.insert({
        textFieldName: 'test text',
        datetimeFieldName: DateTime.now(),
      });
      expect(insertedId, 1);
    },
  );

  test(
    'select',
    () async {
      final table = sqliteDatabase.getTable(tableName);

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

  group(
    'selectByPk',
    () {
      test(
        ': found.',
        () async {
          final table = sqliteDatabase.getTable(tableName);

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
        ': not found.',
        () async {
          final table = sqliteDatabase.getTable(tableName);

          const findCondition = 1;
          expect(
            () => table.selectByPk(findCondition),
            throwsA(
              (e) =>
                  e is NotFoundException &&
                  e.toString() ==
                      'Not found.'
                          ' {'
                          ' target: $tableName'
                          ', conditions: { $pkName = $findCondition }'
                          ' }',
            ),
          );
        },
      );
    },
  );

  group('updateByPk', () {
    test(
      ': success',
      () async {
        final table = sqliteDatabase.getTable(tableName);

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
      ': target is nothing',
      () async {
        final table = sqliteDatabase.getTable(tableName);

        final beforeUpdate = await table.select();
        assert(beforeUpdate.isEmpty);

        final datetime = DateTime.now();
        final test = {
          textFieldName: 'test text',
          datetimeFieldName: datetime,
        };

        expect(
          () async => await table.updateByPk(1, test),
          throwsA((e) => e is NotFoundException),
        );

        final afterUpdateFail = await table.select();
        expect(afterUpdateFail.length, 0);
      },
    );
  });

  test(
    'deleteById',
    () async {
      final table = sqliteDatabase.getTable(tableName);

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
      final table = sqliteDatabase.getTable(tableName);

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
