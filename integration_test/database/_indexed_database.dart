import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/logger.dart';

import 'definitions.dart';

void main() {
  Logger(level: Level.verbose);

  testIndexedDatabase();
}

void testIndexedDatabase() => group(
      'IndexedDatabase test',
      () {
        group('Database operation', () {
          test(
            'open',
            () async {
              final created = await IndexedDatabase(defD).open();

              expect(created.definition.name, defD.name);
              expect(created.tables.length, defD.tableDefinitions.length);
            },
            tags: 'Medium',
          );

          group('Migrate: upgrade', () {
            late IndexedDatabase indexedDatabase;

            setUp(() async {
              indexedDatabase = await IndexedDatabase(defD).open();
            });
            tearDown(() async {
              await indexedDatabase.delete();
            });

            test(
              ': add table',
              () async {
                await indexedDatabase.close();

                final upgraded =
                    await IndexedDatabase(upgradingByAddTableDefD).open();

                final addedTable =
                    upgraded.getTable(addingTableDefinition.name);
                expect(addedTable, isNotNull);

                final insertedId = await addedTable.insert({'test': 'test'});
                expect(insertedId, isNotNull);
              },
              tags: 'Medium',
            );

            test(
              ': add column',
              () async {
                final test = {
                  textFieldName: 'test text',
                  datetimeFieldName: DateTime.now(),
                };

                final insertedId =
                    await indexedDatabase.getTable(testTable.name).insert(test);
                final insertedChildrenId =
                    await indexedDatabase.getTable(testChildTable.name).insert({
                  'tests_id': insertedId,
                });

                await indexedDatabase.close();

                final upgraded =
                    await IndexedDatabase(upgradingByAddColumnDefD).open();

                final tests = await upgraded.getTable(testTable.name).select();
                expect(tests, [
                  {'id': insertedId, 'adding_column': null, ...test}
                ]);
                final testChildren =
                    await upgraded.getTable(testChildTable.name).select();
                expect(testChildren, [
                  {'id': insertedChildrenId, 'tests_id': insertedId}
                ]);
              },
              tags: 'Medium',
            );
          });
        });

        test(
          'Indexed database: require at least 1 table.',
          () async {
            final defD = DefD(dbName, dbVersion, []);
            expect(
              () => IndexedDatabase(defD),
              throwsA(
                (e) =>
                    e is DatabaseException &&
                    e.message == 'Requires at least 1 table.',
              ),
            );
          },
          tags: 'Medium',
        );
      },
    );
