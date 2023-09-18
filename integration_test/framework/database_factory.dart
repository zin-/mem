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
      setUpAll(() {
        DatabaseFactory.onTest = true;
      });
      setUp(() async {
        for (final testDefDatabase in [
          sampleDefDb,
          sampleDefDBAddedTable,
          sampleDefDBAddedColumn,
        ]) {
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(
            await DatabaseFactory.buildDatabasePath(testDefDatabase.name),
          );
        }
      });
      tearDownAll(() {
        DatabaseFactory.onTest = false;
      });

      group(": open", () {
        test(
          ": once.",
          () async {
            final database = (await DatabaseFactory.open(sampleDefDb))
                // ignore: deprecated_member_use_from_same_package
                .nativeDatabase;

            expect(
              path.split(database.path).last,
              "test_${sampleDefDb.name}",
            );

            final tables = await database.query(
              'sqlite_master',
              columns: ["name", "sql"],
            );
            for (var tableDefinition in sampleDefDb.tableDefinitions) {
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

        group(": as no onTest", () {
          setUpAll(() {
            DatabaseFactory.onTest = false;
          });
          tearDownAll(() {
            DatabaseFactory.onTest = true;
          });

          test(
            ": database has no \"test_\".",
            () async {
              final database = (await DatabaseFactory.open(sampleDefDb))
                  // ignore: deprecated_member_use_from_same_package
                  .nativeDatabase;

              expect(
                path.split(database.path).last,
                sampleDefDb.name,
              );
              expect(
                path.split(database.path).last,
                isNot(contains("test_")),
              );
            },
          );
        });

        test(
          ": twice.",
          () async {
            await DatabaseFactory.open(sampleDefDb);
            await DatabaseFactory.open(sampleDefDb);

            // check did not throw
            expect(true, true);
          },
        );

        group(": upgrade", () {
          test(
            ": do not upgrade if have not been closed.",
            () async {
              final database = (await DatabaseFactory.open(sampleDefDb))
                  // ignore: deprecated_member_use_from_same_package
                  .nativeDatabase;
              final database2 =
                  (await DatabaseFactory.open(sampleDefDBAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              expect(database, database2);
              expect(
                await database2.getVersion(),
                sampleDefDb.version,
              );
            },
          );

          test(
            ": add table.",
            () async {
              final database = (await DatabaseFactory.open(sampleDefDb))
                  // ignore: deprecated_member_use_from_same_package
                  .nativeDatabase;

              // 対象のDBがopenedの場合、upgrade処理が実行されないためcloseする
              await database.close();

              final database2 =
                  (await DatabaseFactory.open(sampleDefDBAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              expect(database.isOpen, false);
              expect(database, isNot(database2));
              expect(
                await database2.getVersion(),
                sampleDefDBAddedTable.version,
              );

              final tables = await database2.query(
                'sqlite_master',
                columns: ["name", "sql"],
              );
              for (var tableDefinition
                  in sampleDefDBAddedTable.tableDefinitions) {
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
                  (await DatabaseFactory.open(sampleDefDBAddedTable))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              // データ移行が行われるかの確認のためデータを挿入する
              final testId = await database.insert(sampleDefTable.name, {
                sampleDefColInteger.name: 999,
                sampleDefColText.name: 'sample text',
                sampleDefColTimeStamp.name: DateTime.now().toIso8601String(),
                sampleDefColBoolean.name: 0,
              });
              await database.insert(
                sampleDefTableChild.name,
                {
                  sampleDefFkChild.name: testId,
                },
              );

              // 対象のDBがopenedの場合、upgrade処理が実行されないためcloseする
              await database.close();

              final database2 =
                  (await DatabaseFactory.open(sampleDefDBAddedColumn))
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase;

              expect(database.isOpen, false);
              expect(database, isNot(database2));
              expect(
                await database2.getVersion(),
                sampleDefDBAddedColumn.version,
              );

              final tables = await database2.query(
                'sqlite_master',
                columns: ["name", "sql"],
              );
              for (var tableDefinition
                  in sampleDefDBAddedColumn.tableDefinitions) {
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
