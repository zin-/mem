import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/definitions/column_definition.dart';
import 'package:mem/database/definitions/table_definition.dart';
import 'package:mem/database/sqlite_database.dart';

// FIXME integration testでrepositoryを参照するのはNG
import 'package:mem/repositories/_database_tuple_repository.dart';

import '../_helpers.dart';
import 'definitions.dart';

void main() {
  testSqliteDatabase();
}

void testSqliteDatabase() => group(
      'SqliteDatabase test',
      () {
        group('Database operation', () {
          if (Platform.isAndroid || Platform.isWindows) {
            test(
              ': open',
              () async {
                final created = await SqliteDatabase(defD).open();

                expect(created.definition.name, defD.name);
                expect(created.tables.length, defD.tableDefinitions.length);
              },
              tags: TestSize.medium,
            );

            test(
              'getTable: not found',
              () async {
                final created = await SqliteDatabase(defD).open();

                expect(
                  () => created.getTable('not_found'),
                  throwsA((e) {
                    expect(e, isA<DatabaseException>());
                    return true;
                  }),
                );
              },
              tags: TestSize.medium,
            );

            group('Migrate: upgrade', () {
              late SqliteDatabase sqliteDatabase;

              setUp(() async {
                sqliteDatabase = await SqliteDatabase(defD).open();
              });
              tearDown(() async {
                await sqliteDatabase.delete();
              });

              test(
                ': add table',
                () async {
                  await sqliteDatabase.close();

                  final addingTableDefinition = TableDefinition(
                    'added_table',
                    [
                      PrimaryKeyDefinition(idColumnName, ColumnType.integer,
                          autoincrement: true),
                      ColumnDefinition('test', ColumnType.text),
                    ],
                  );
                  final upgradingDefD = DatabaseDefinition(
                    defD.name,
                    2,
                    [
                      ...defD.tableDefinitions,
                      addingTableDefinition,
                    ],
                  );

                  final upgraded = await SqliteDatabase(upgradingDefD).open();

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

                  final insertedId = await sqliteDatabase
                      .getTable(testTable.name)
                      .insert(test);
                  final insertedChildrenId = await sqliteDatabase
                      .getTable(testChildTable.name)
                      .insert({
                    'tests_id': insertedId,
                  });

                  await sqliteDatabase.close();

                  final upgradingDefD = DatabaseDefinition(
                    defD.name,
                    2,
                    [
                      TableDefinition(
                        testTable.name,
                        [
                          ...testTable.columns,
                          ColumnDefinition('adding_column', ColumnType.datetime,
                              notNull: false),
                        ],
                      ),
                      testChildTable,
                    ],
                  );

                  final upgraded = await SqliteDatabase(upgradingDefD).open();

                  final tests =
                      await upgraded.getTable(testTable.name).select();
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
          }

          if (kIsWeb) {
            final defD = DatabaseDefinition('test_sqlite.db', 1, []);

            test(
              'Error on Chrome.',
              () async {
                expect(
                  () => SqliteDatabase(defD),
                  throwsA(
                    (e) =>
                        e is DatabaseException &&
                        e.message == 'Unsupported platform. Platform: Web',
                  ),
                );
              },
              tags: TestSize.medium,
            );
          }
        });

        group('Table Operating', () {
          if (Platform.isAndroid || Platform.isWindows) {
            late SqliteDatabase sqliteDatabase;

            setUp(() async {
              sqliteDatabase = await SqliteDatabase(defD).open();
            });
            tearDown(() async {
              await sqliteDatabase.delete();
            });

            group(': insert', () {
              test(
                ': testTable',
                () async {
                  final table = sqliteDatabase.getTable(tableName);

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
                    final table = sqliteDatabase.getTable(testChildTable.name);

                    expect(
                      () async => await table.insert({
                        'tests_id': 1,
                      }),
                      throwsA((e) {
                        // FIXME 固有の例外に置き換えたい
                        expect(e, isA<Exception>());
                        return true;
                      }),
                    );
                  },
                  tags: TestSize.medium,
                );

                test(
                  ': success',
                  () async {
                    final table = sqliteDatabase.getTable(testTable.name);
                    final childTable =
                        sqliteDatabase.getTable(testChildTable.name);

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
              tags: TestSize.medium,
            );

            group(
              ': selectByPk',
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
                  tags: TestSize.medium,
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
                  tags: TestSize.medium,
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
                tags: TestSize.medium,
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
                tags: TestSize.medium,
              );
            });

            test(
              ': deleteById',
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
              tags: TestSize.medium,
            );

            test(
              ': deleteAll',
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
              tags: TestSize.medium,
            );
          }
        });
      },
    );
