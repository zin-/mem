import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mem_repeated_notifications.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service.dart';

import 'helpers.dart';

void main() {
  LogService.initialize(Level.verbose);
  testHabitScenario();
}

const _scenarioName = 'Habit scenario';

void testHabitScenario() => group(': $_scenarioName', () {
      const insertedMemName = '$_scenarioName - mem name - inserted';
      const withRepeatedMemName = '$insertedMemName - with repeated';
      const timeOfDaySeconds = 1000;

      late final Database db;
      late final int insertedMemId;
      late final int withRepeatedMemId;

      setUpAll(() async {
        db = await DatabaseManager(onTest: true).open(databaseDefinition);

        await resetDatabase(db);

        final memTable = db.getTable(memTableDefinition.name);
        insertedMemId = await memTable.insert({
          defMemName.name: insertedMemName,
          createdAtColDef.name: DateTime.now(),
        });
        withRepeatedMemId = await memTable.insert({
          defMemName.name: withRepeatedMemName,
          createdAtColDef.name: DateTime.now(),
        });
        await db.getTable(memRepeatedNotificationTableDefinition.name).insert({
          timeOfDaySecondsColDef.name: timeOfDaySeconds,
          memIdFkDef.name: withRepeatedMemId,
          createdAtColDef.name: DateTime.now(),
        });
      });

      testWidgets(': Set repeated notification.', (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(insertedMemName));
        await widgetTester.pumpAndSettle();

        final pickTime = DateTime.now();
        await widgetTester.tap(timeIconFinder);
        await widgetTester.pump();

        await widgetTester.tap(okFinder);
        await widgetTester.pump();

        expect(
          (widgetTester.widget(memRepeatedNotificationOnDetailPageFinder())
                  as TextFormField)
              .initialValue,
          timeText(pickTime),
        );
        await widgetTester.tap(saveMemFabFinder);
        await widgetTester.pump();

        await widgetTester.tap(timeIconFinder);
        await widgetTester.pump();

        await widgetTester.tap(okFinder);
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(saveMemFabFinder);
        await widgetTester.pumpAndSettle();

        await Future(() async {
          late final Map<String, dynamic> inserted;

          await expectLater(
            inserted = (await db
                    .getTable(memRepeatedNotificationTableDefinition.name)
                    .select(
              whereString: '${memIdFkDef.name} = ?',
              whereArgs: [insertedMemId],
            ))
                .single,
            isNotNull,
          );
          final timeOfDay = TimeOfDay.fromDateTime(pickTime);
          await expectLater(
            inserted[timeOfDaySecondsColDef.name],
            ((timeOfDay.hour * 60) + timeOfDay.minute) * 60,
          );
          await expectLater(
            inserted[createdAtColDef.name],
            isNotNull,
          );
          await expectLater(
            inserted[updatedAtColDef.name],
            isNotNull,
          );
          await expectLater(
            inserted[archivedAtColDef.name],
            isNull,
          );
          await expectLater(
            inserted[memIdFkDef.name],
            insertedMemId,
          );
        });
      });

      testWidgets(': Unset repeated notification.', (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(withRepeatedMemName));
        await widgetTester.pumpAndSettle();

        expect(
          (widgetTester.widget(memRepeatedNotificationOnDetailPageFinder())
                  as TextFormField)
              .initialValue,
          '12:16 AM',
        );
        await widgetTester.tap(clearIconFinder);
        await widgetTester.pump();

        expect(
          (widgetTester.widget(memRepeatedNotificationOnDetailPageFinder())
                  as TextFormField)
              .initialValue,
          '',
        );
        await widgetTester.tap(saveMemFabFinder);
        await widgetTester.pumpAndSettle();

        await Future(
          () async {
            final memRepeatedNotifications = (await db
                .getTable(memRepeatedNotificationTableDefinition.name)
                .select(
              whereString: '${memIdFkDef.name} = ?',
              whereArgs: [withRepeatedMemId],
            ));
            await expectLater(memRepeatedNotifications.length, 0);
          },
        );
      });
    });
