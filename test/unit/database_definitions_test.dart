import 'package:flutter_test/flutter_test.dart';

import 'package:mem/database/definitions.dart';

void main() {
  group('Column', () {
    group('new', () {
      test('success.', () {
        const columnName = 'test';

        final columnDefinition = ColumnDefinition(columnName, ColumnType.text);

        expect(columnDefinition.toString(), contains(columnName));
      });
      test('empty name.', () {
        expect(
          () => ColumnDefinition('', ColumnType.text),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Column name is required.'),
        );
      });
    });
  });

  group('Table', () {
    group('new', () {
      test('success.', () {
        const tableName = 'tests';
        const columnName = 'test';

        final tableDefinition = TableDefinition(
          tableName,
          [
            PrimaryKeyDefinition(columnName, ColumnType.integer),
          ],
        );

        expect(tableDefinition.toString(), contains(tableName));
        expect(tableDefinition.toString(), contains(columnName));
      });
      test('empty name.', () {
        expect(
          () => TableDefinition(
            '',
            [],
          ),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Table name is required.'),
        );
      });
      test('no columns.', () {
        expect(
          () => TableDefinition(
            'tests',
            [],
          ),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Table columns are required.'),
        );
      });
      test('no primary key.', () {
        expect(
          () => TableDefinition('tests', [
            ColumnDefinition('test', ColumnType.text),
          ]),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Primary key is required.'),
        );
      });
      test('two primary key.', () {
        expect(
          () => TableDefinition('tests', [
            PrimaryKeyDefinition('pk1', ColumnType.text),
            PrimaryKeyDefinition('pk2', ColumnType.text),
          ]),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Only one primary key is allowed.'),
        );
      });
      test('duplicate columns.', () {
        expect(
          () => TableDefinition(
            'tests',
            [
              PrimaryKeyDefinition('pk', ColumnType.text),
              ColumnDefinition('dup', ColumnType.text),
              ColumnDefinition('dup', ColumnType.text),
            ],
          ),
          throwsA((e) =>
              e is DatabaseDefinitionException &&
              e.toString() == 'Duplicated column names are not allowed.'),
        );
      });
    });

    test('buildCreateSql', () {
      const tableName = 'tests';

      final tableDefinition = TableDefinition(
        tableName,
        [
          PrimaryKeyDefinition('id', ColumnType.integer, autoincrement: true),
          ColumnDefinition('text', ColumnType.text),
          ColumnDefinition('datetime', ColumnType.datetime, notNull: false),
        ],
      );

      expect(
        tableDefinition.buildCreateTableSql(),
        'CREATE TABLE tests ('
        ' id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'
        ' text TEXT NOT NULL,'
        ' datetime TIMESTAMP'
        ' )',
      );
    });
  });

  group('Database', () {
    group('new', () {
      test('success.', () {
        const dbName = 'test.db';
        const dbVersion = 1;
        const tableName = 'tests';
        const pkName = 'test_pk';
        final pk = PrimaryKeyDefinition(pkName, ColumnType.text);
        final tableDefinitions = [
          TableDefinition(tableName, [pk])
        ];

        final databaseDefinition =
            DatabaseDefinition(dbName, dbVersion, tableDefinitions);

        expect(databaseDefinition.toString(), contains(dbName));
        expect(databaseDefinition.toString(), contains(dbVersion.toString()));
        expect(databaseDefinition.toString(), contains(tableName));
      });
    });
    test('empty name.', () {
      expect(
        () => DatabaseDefinition(
          '',
          1,
          [],
        ),
        throwsA((e) =>
            e is DatabaseDefinitionException &&
            e.toString() == 'Database name is required.'),
      );
    });
    test('version is less than 1.', () {
      expect(
        () => DatabaseDefinition(
          'test.db',
          0,
          [],
        ),
        throwsA((e) =>
            e is DatabaseDefinitionException &&
            e.toString() == 'Minimum version is 1.'),
      );
    });
  });
}
