import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/database_tuple_repository.dart';

import 'definitions.dart';

void main() {
  Logger(level: Level.verbose);

  testSqliteDatabase();
}

void testSqliteDatabase() => group(
      'SqliteDatabase test',
      () {
        if (Platform.isAndroid || Platform.isWindows) {
          late SqliteDatabase sqliteDatabase;

          setUp(() async {
            sqliteDatabase = await SqliteDatabase(defD).open();
          });
          tearDown(() async {
            await sqliteDatabase.delete();
          });

          group('Migrate: upgrade', () {
            test(
              ': add table',
              () async {
                await sqliteDatabase.close();

                final addingTableDefinition = DefT(
                  'added_table',
                  [
                    DefPK(idColumnName, TypeC.integer, autoincrement: true),
                    DefC('test', TypeC.text),
                  ],
                );
                final upgradingDefD = DefD(
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
                    await sqliteDatabase.getTable(testTable.name).insert(test);
                final insertedChildrenId =
                    await sqliteDatabase.getTable(testChildTable.name).insert({
                  'tests_id': insertedId,
                });

                await sqliteDatabase.close();

                final upgradingDefD = DefD(
                  defD.name,
                  2,
                  [
                    DefT(
                      testTable.name,
                      [
                        ...testTable.columns,
                        DefC('adding_column', TypeC.datetime, notNull: false),
                      ],
                    ),
                    testChildTable,
                  ],
                );

                final upgraded = await SqliteDatabase(upgradingDefD).open();

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

          group(('Operating'), () {
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
                tags: 'Medium',
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
                  tags: 'Medium',
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
                  tags: 'Medium',
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
              tags: 'Medium',
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
                  tags: 'Medium',
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
                  tags: 'Medium',
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
                tags: 'Medium',
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
                tags: 'Medium',
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
              tags: 'Medium',
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
              tags: 'Medium',
            );
          });
        }

        if (kIsWeb) {
          final defD = DefD('test_sqlite.db', 1, []);

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
            tags: 'Medium',
          );
        }
      },
    );
