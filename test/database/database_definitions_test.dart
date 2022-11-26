import 'package:flutter_test/flutter_test.dart';

import 'package:mem/database/definitions.dart';
import 'package:mem/database/definitions/column_definition.dart';
import 'package:mem/database/definitions/table_definition.dart';

import '../_helpers.dart';

void main() {
  group('Database', () {
    group(': new', () {
      test(
        ': success.',
        () {
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
        },
        tags: TestSize.small,
      );

      test(
        ': empty name.',
        () {
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
        },
        tags: TestSize.small,
      );

      test(
        ': contains space.',
        () {
          expect(
            () => DatabaseDefinition(
              'test database',
              1,
              [],
            ),
            throwsA((e) =>
                e is DatabaseDefinitionException &&
                e.toString() == 'Database name contains " ".'),
          );
        },
        tags: TestSize.small,
      );

      test(
        ': version is less than 1.',
        () {
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
        },
        tags: TestSize.small,
      );
    });
  });
}
