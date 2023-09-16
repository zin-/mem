import 'package:collection/collection.dart';
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
          databaseAccessor = await DatabaseFactory.open(sampleDefDb, true);
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
                    sampleDefDb.name, true));
          });

          test(": returns false.", () async {
            expect(await databaseAccessor.isOpened(), false);
          });
        });
      });

      group(": operations", () {
        late final DatabaseAccessor databaseAccessor;
        setUpAll(() async {
          databaseAccessor =
              await DatabaseFactory.open(sampleDefDBAddedColumn, true);
        });

        late int maxPkInsertedId;
        setUp(() async {
          maxPkInsertedId = ((await databaseAccessor
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase
                      .query(
                sampleDefTable.name,
                orderBy: "${sampleDefPk.name} DESC",
                limit: 1,
              ))
                  .singleWhereOrNull((element) => true)?[sampleDefPk.name] ??
              0) as int;
        });

        test(": insert", () async {
          final insertedId = await databaseAccessor.insert(sampleDefTable, {
            sampleDefColInteger.name: 1,
            sampleDefColText.name: "$_scenarioName: insert",
          });

          expect(insertedId, maxPkInsertedId + 1);
        });
      });
    });
