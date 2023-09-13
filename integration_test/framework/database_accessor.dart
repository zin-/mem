import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';

import 'definitions.dart';

void main() {
  testDatabaseAccessor();
}

const _scenarioName = "Database accessor test";

void testDatabaseAccessor() => group(": $_scenarioName", () {
      group(": isOpened()", () {
        late DatabaseAccessor databaseAccessor;

        setUp(() async {
          databaseAccessor = await DatabaseFactory.open(testDatabaseDefinition);
        });

        test(": returns true.", () async {
          expect(await databaseAccessor.isOpened(), true);
        });

        group(": when closed", () {
          setUp(() async {
            await databaseAccessor
                // ignore: deprecated_member_use_from_same_package
                .nativeDatabase
                .close();
          });

          test(": returns false.", () async {
            expect(await databaseAccessor.isOpened(), false);
          });
        });

        group(": when deleted", () {
          setUp(() async {
            await DatabaseFactory
                // ignore: deprecated_member_use_from_same_package
                .nativeFactory
                .deleteDatabase(await DatabaseFactory.buildDatabasePath(
                    testDatabaseDefinition.name));
          });

          test(": returns false.", () async {
            expect(await databaseAccessor.isOpened(), false);
          });
        });
      });
    });
