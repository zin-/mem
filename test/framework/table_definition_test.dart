import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/primary_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

void main() {
  group('Table', () {
    group(': new', () {
      test(
        ': success.',
        () {
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
        },
      );

      test(
        ': empty name.',
        () {
          expect(
            () => TableDefinition(
              '',
              [],
            ),
            throwsA((e) =>
                e is TableDefinitionException &&
                e.toString() == 'Table name is required.'),
          );
        },
      );

      test(
        ': contains space.',
        () {
          expect(
            () => TableDefinition(
              'test table',
              [],
            ),
            throwsA((e) =>
                e is TableDefinitionException &&
                e.toString() == 'Table name contains " ".'),
          );
        },
      );

      test(
        ': no columns.',
        () {
          expect(
            () => TableDefinition(
              'tests',
              [],
            ),
            throwsA((e) =>
                e is TableDefinitionException &&
                e.toString() == 'Table columns are required.'),
          );
        },
      );

      test(
        ': no primary key.',
        () {
          expect(
            () => TableDefinition('tests', [
              ColumnDefinition('test', ColumnType.text),
            ]),
            throwsA((e) =>
                e is TableDefinitionException &&
                e.toString() == 'Primary key is required.'),
          );
        },
      );

      test(
        ': two primary key.',
        () {
          expect(
            () => TableDefinition('tests', [
              PrimaryKeyDefinition('pk1', ColumnType.text),
              PrimaryKeyDefinition('pk2', ColumnType.text),
            ]),
            throwsA((e) =>
                e is TableDefinitionException &&
                e.toString() == 'Only one primary key is allowed.'),
          );
        },
      );

      test(
        ': duplicate columns.',
        () {
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
                e is TableDefinitionException &&
                e.toString() == 'Duplicated column names are not allowed.'),
          );
        },
      );
    });

    group(': buildCreateSql', () {
      test(
        ': single table',
        () {
          const tableName = 'tests';

          final tableDefinition = TableDefinition(
            tableName,
            [
              PrimaryKeyDefinition('id', ColumnType.integer,
                  autoincrement: true),
              ColumnDefinition('text', ColumnType.text),
              ColumnDefinition('datetime', ColumnType.datetime, notNull: false),
            ],
          );

          expect(
            tableDefinition.buildCreateTableSql(),
            'CREATE TABLE tests ('
            ' id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'
            ' text TEXT NOT NULL,'
            ' datetime TIMESTAMP DEFAULT NULL'
            ' )',
          );
        },
      );

      test(
        ': 2 tables with foreign key',
        () {
          final tableDefinition = TableDefinition(
            'tests',
            [
              PrimaryKeyDefinition('id', ColumnType.integer,
                  autoincrement: true),
            ],
          );
          final childTableDefinition = TableDefinition(
            'testChildren',
            [
              PrimaryKeyDefinition('id', ColumnType.integer,
                  autoincrement: true),
              ForeignKeyDefinition(tableDefinition),
            ],
          );

          expect(
            childTableDefinition.buildCreateTableSql(),
            'CREATE TABLE ${childTableDefinition.name} ('
            ' id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'
            ' tests_id INTEGER NOT NULL,'
            ' FOREIGN KEY (tests_id) REFERENCES tests(id)'
            ' )',
          );
        },
      );
    });
  });
}
