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
        final inserted = {
          sampleDefPk.name: 0,
          sampleDefColInteger.name: 0,
          sampleDefColText.name: "$_scenarioName: operations: inserted",
        };

        late final DatabaseAccessor databaseAccessor;
        late final int maxPkInsertedId;
        setUpAll(() async {
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(await DatabaseFactory.buildDatabasePath(
                  sampleDefDb.name, true));

          databaseAccessor =
              await DatabaseFactory.open(sampleDefDBAddedColumn, true);

          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .insert(sampleDefTable.name, inserted);

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

        test(": insert.", () async {
          final insertedId = await databaseAccessor.insert(sampleDefTable, {
            sampleDefColInteger.name: 1,
            sampleDefColText.name: "$_scenarioName: operations: insert",
          });

          expect(insertedId, maxPkInsertedId + 1);
        });

        test(": select.", () async {
          final selected = await databaseAccessor.select(
            sampleDefTable,
            orderBy: "${sampleDefPk.name} ASC",
            limit: 1,
          );

          expect(selected, [inserted]);
        });

        test(": update.", () async {
          final updatedCount = await databaseAccessor.update(
            sampleDefTable,
            {
              sampleDefColInteger.name: 999,
              sampleDefColText.name: "$_scenarioName: operations: update",
            },
            where: "${sampleDefPk.name} = ?",
            whereArgs: [inserted[sampleDefPk.name]],
          );

          expect(updatedCount, 1);
        });
      });
    });
