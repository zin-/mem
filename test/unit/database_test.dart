import 'package:flutter_test/flutter_test.dart';

import 'package:mem/database/database.dart';

void main() {
  group('DatabaseTableDefinition', () {
    group('new', () {
      test('define.', () {
        const tableName = 'tests';

        final tableDefinition = TableDefinition(tableName, [
          PrimaryKeyDefinition('id', FieldType.integer),
        ]);

        expect(tableDefinition.toString(), contains(tableName));
      });
      test('empty name.', () {
        expect(
          () => TableDefinition('', []),
          throwsA((e) => e is DatabaseException),
        );
      });
      test('no fields.', () {
        expect(
          () => TableDefinition('tests', []),
          throwsA((e) => e is DatabaseException),
        );
      });
      test('no primary key.', () {
        expect(
          () => TableDefinition('tests', [
            FieldDefinition('test', FieldType.text),
          ]),
          throwsA((e) => e is DatabaseException),
        );
      });
      test('two primary key.', () {
        expect(
          () => TableDefinition('tests', [
            PrimaryKeyDefinition('test1', FieldType.text),
            PrimaryKeyDefinition('test2', FieldType.text),
          ]),
          throwsA((e) => e is DatabaseException),
        );
      });
    });

    test('buildCreateSql', () {
      const tableName = 'tests';

      final tableDefinition = TableDefinition(
        tableName,
        [
          PrimaryKeyDefinition('id', FieldType.integer, autoincrement: true),
          FieldDefinition('text', FieldType.text),
        ],
      );

      expect(
        tableDefinition.buildCreateSql(),
        'CREATE TABLE tests ( id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT )',
      );
    });
  });
}
