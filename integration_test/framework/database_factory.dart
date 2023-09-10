import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

import 'definitions.dart';

void main() {
  testDatabaseFactoryV2();
}

const _scenarioName = "Database factory test V2";

void testDatabaseFactoryV2() => group(": $_scenarioName", () {
      setUp(() async {
        for (final testDefDatabase in [
          testDatabaseDefinition,
          testDatabaseDefinitionAddedTable,
          testDatabaseDefinitionAddedColumn,
        ]) {
          await DatabaseFactory.nativeFactory.deleteDatabase(
            await DatabaseFactory.buildDatabasePath(testDefDatabase.name),
          );
        }
      });

      group(": open", () {
        test(
          ": once.",
          () async {
            final database =
                (await DatabaseFactory.open(testDatabaseDefinition))
                    // ignore: deprecated_member_use_from_same_package
                    .nativeDatabase;

            expect(
              path.split(database.path).last,
              testDatabaseDefinition.name,
            );

            final tables = await database.query(
              'sqlite_master',
              columns: ["name", "sql"],
            );
            for (var tableDefinition
                in testDatabaseDefinition.tableDefinitions) {
              for (var table in tables) {
                if (table["name"] == tableDefinition.name) {
                  expect(
                    table["sql"],
                    tableDefinition.buildCreateTableSql(),
                  );
                }
              }
            }
          },
        );

        test(
          ": twice.",
          () async {
            await DatabaseFactory.open(testDatabaseDefinition);
            await DatabaseFactory.open(testDatabaseDefinition);

            // check did not throw
            expect(true, true);
          },
        );

        group(": upgrade", () {
          test(
            ": do not upgrade if have not been closed.",
            () async {
              final database =
                  (await DatabaseFactory.open(testDatabaseDefinition))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;
              final database2 =
                  (await DatabaseFactory.open(testDatabaseDefinitionAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              expect(database, database2);
              expect(
                await database2.getVersion(),
                testDatabaseDefinition.version,
              );
            },
          );

          test(
            ": add table.",
            () async {
              final database =
                  (await DatabaseFactory.open(testDatabaseDefinition))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              // 対象のDBがopenedの場合、upgrade処理が実行されないためcloseする
              await database.close();

              final database2 =
                  (await DatabaseFactory.open(testDatabaseDefinitionAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              expect(database.isOpen, false);
              expect(database, isNot(database2));
              expect(
                await database2.getVersion(),
                testDatabaseDefinitionAddedTable.version,
              );

              final tables = await database2.query(
                'sqlite_master',
                columns: ["name", "sql"],
              );
              for (var tableDefinition
                  in testDatabaseDefinitionAddedTable.tableDefinitions) {
                for (var table in tables) {
                  if (table["name"] == tableDefinition.name) {
                    expect(
                      table["sql"],
                      tableDefinition.buildCreateTableSql(),
                    );
                  }
                }
              }
            },
          );

          test(
            ": add column.",
            () async {
              final database =
                  (await DatabaseFactory.open(testDatabaseDefinitionAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              // データ移行が行われるかの確認のためデータを挿入する
              final testId = await database.insert(testTableDefinition.name, {
                testDefInteger.name: 999,
                testDefText.name: 'sample text',
              });
              await database.insert(
                testChildTableDefinition.name,
                {
                  testDefFk.name: testId,
                  testDefTimeStamp.name: DateTime.now().toIso8601String(),
                },
              );

              // 対象のDBがopenedの場合、upgrade処理が実行されないためcloseする
              await database.close();

              final database2 = (await DatabaseFactory.open(
                      testDatabaseDefinitionAddedColumn))
                  // ignore: deprecated_member_use_from_same_package
                  .nativeDatabase;

              expect(database.isOpen, false);
              expect(database, isNot(database2));
              expect(
                await database2.getVersion(),
                testDatabaseDefinitionAddedColumn.version,
              );

              final tables = await database2.query(
                'sqlite_master',
                columns: ["name", "sql"],
              );
              for (var tableDefinition
                  in testDatabaseDefinitionAddedColumn.tableDefinitions) {
                for (var table in tables) {
                  if (table["name"] == tableDefinition.name) {
                    expect(
                      table["sql"],
                      tableDefinition.buildCreateTableSql(),
                    );
                  }
                }
              }
            },
          );
        });
      });
    });
