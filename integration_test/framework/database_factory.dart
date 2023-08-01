import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:path/path.dart' as path;

import 'definitions.dart';

void main() {
  testDatabaseFactoryV2();
}

const _scenarioName = "Database factory test V2";

void testDatabaseFactoryV2() => group(": $_scenarioName", () {
      setUp(() async {
        await DatabaseFactory.nativeFactory.deleteDatabase(
          await DatabaseFactory.buildDatabasePath(testDatabaseDefinition.name),
        );
      });

      // TODO add upgrade
      group(": open", () {
        test(": once.", () async {
          final database = (await DatabaseFactory.open(testDatabaseDefinition))
              .nativeDatabase;

          expect(
            path.split(database.path).last,
            testDatabaseDefinition.name,
          );
          expect(
            (await database.query(
              'sqlite_master',
              where: 'name = ?',
              whereArgs: [
                testTableDefinition.name,
              ],
            ))
                .single['sql'],
            testTableDefinition.buildCreateTableSql(),
          );
          expect(
            (await database.query(
              'sqlite_master',
              where: 'name = ?',
              whereArgs: [
                testChildTableDefinition.name,
              ],
            ))
                .single['sql'],
            testChildTableDefinition.buildCreateTableSql(),
          );
        });

        test(": twice.", () async {
          await DatabaseFactory.open(testDatabaseDefinition);
          await DatabaseFactory.open(testDatabaseDefinition);

          // check did not throw
          expect(true, true);
        });
      });
    });
