import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/indexed_database.dart';

import '../_helpers.dart';
import 'definitions.dart';

void main() {
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
            tags: TestSize.medium,
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
              tags: TestSize.medium,
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
              tags: TestSize.medium,
            );
          });
        });

        group(('Table operation'), () {
          late IndexedDatabase indexedDatabase;
          setUp(() async {
            indexedDatabase = await IndexedDatabase(defD).open();
          });
          tearDown(() async {
            await indexedDatabase.delete();
          });

          group(': insert', () {
            test(
              ': testTable',
              () async {
                final table = indexedDatabase.getTable(tableName);

                final insertedId = await table.insert({
                  textFieldName: 'test text',
                  datetimeFieldName: DateTime.now(),
                });
                expect(insertedId, 1);
              },
              tags: TestSize.medium,
            );

            group('testChildTable', () {
              test(
                ': no parent',
                () async {
                  final table = indexedDatabase.getTable(testChildTable.name);

                  expect(
                    () async => await table.insert({
                      'tests_id': 1,
                    }),
                    throwsA((e) {
                      expect(e, isA<ParentNotFoundException>());
                      return true;
                    }),
                  );
                },
                tags: TestSize.medium,
              );

              test(
                ': success',
                () async {
                  final table = indexedDatabase.getTable(testTable.name);
                  final childTable =
                      indexedDatabase.getTable(testChildTable.name);

                  final insertedChildId = await childTable.insert({
                    'tests_id': await table.insert({
                      textFieldName: 'test text',
                      datetimeFieldName: DateTime.now(),
                    }),
                  });

                  expect(insertedChildId, 1);
                },
                tags: TestSize.medium,
              );
            });
          });

          test(
            ': select',
            () async {
              final table = indexedDatabase.getTable(tableName);

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
            tags: TestSize.medium,
          );

          group(
            ': selectByPk',
            () {
              test(
                ': found.',
                () async {
                  final table = indexedDatabase.getTable(tableName);

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
                tags: TestSize.medium,
              );

              test(
                ': not found.',
                () async {
                  final table = indexedDatabase.getTable(tableName);

                  const findCondition = 1;
                  expect(
                    () => table.selectByPk(findCondition),
                    throwsA((e) {
                      expect(e, isA<NotFoundException>());
                      return true;
                    }),
                  );
                },
                tags: TestSize.medium,
              );
            },
          );

          group('updateByPk', () {
            test(
              ': success',
              () async {
                final table = indexedDatabase.getTable(tableName);

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
              tags: TestSize.medium,
            );

            test(
              ': target is nothing',
              () async {
                final table = indexedDatabase.getTable(tableName);

                final beforeUpdate = await table.select();
                assert(beforeUpdate.isEmpty);

                final datetime = DateTime.now();
                final test = {
                  textFieldName: 'test text',
                  datetimeFieldName: datetime,
                };

                expect(
                  () async => await table.updateByPk(1, test),
                  throwsA((e) {
                    expect(e, isA<NotFoundException>());
                    return true;
                  }),
                );

                final afterUpdateFail = await table.select();
                expect(afterUpdateFail.length, 0);
              },
              tags: TestSize.medium,
            );
          });

          test(
            ': deleteById',
            () async {
              final table = indexedDatabase.getTable(tableName);

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
            tags: TestSize.medium,
          );

          test(
            ': deleteAll',
            () async {
              final table = indexedDatabase.getTable(tableName);

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
            tags: TestSize.medium,
          );
        });
      },
    );
