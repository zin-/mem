import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mem_notifications.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';

import 'helpers.dart';

void main() {
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
        await db.getTable(memNotificationTableDefinition.name).insert({
          timeColDef.name: timeOfDaySeconds,
          memIdFkDef.name: withRepeatedMemId,
          createdAtColDef.name: DateTime.now(),
        });
      });
      setUp(() async {
        await db.getTable(memNotificationTableDefinition.name).delete(
          whereString: '${memIdFkDef.name} = ?',
          whereArgs: [
            insertedMemId,
          ],
        );
      });

      group(': Repeated notification', () {
        testWidgets(': Set.', (widgetTester) async {
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
            (widgetTester.widget(memNotificationOnDetailPageFinder)
                    as TextFormField)
                .initialValue,
            timeText(pickTime),
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          await widgetTester.tap(timeIconFinder);
          await widgetTester.pump();

          await widgetTester.tap(okFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await Future.delayed(
            waitSideEffectDuration,
            () async {
              late final Map<String, dynamic> inserted;

              await expectLater(
                inserted = (await db
                        .getTable(memNotificationTableDefinition.name)
                        .select(
                  whereString: '${memIdFkDef.name} = ?',
                  whereArgs: [insertedMemId],
                ))
                    .single,
                isNotNull,
              );
              final timeOfDay = TimeOfDay.fromDateTime(pickTime);
              await expectLater(
                [
                  inserted[timeColDef.name],
                  inserted[createdAtColDef.name],
                  inserted[updatedAtColDef.name],
                  inserted[archivedAtColDef.name],
                  inserted[memIdFkDef.name],
                ],
                [
                  ((timeOfDay.hour * 60) + timeOfDay.minute) * 60,
                  isNotNull,
                  isNotNull,
                  isNull,
                  insertedMemId,
                ],
              );
            },
          );
        });

        testWidgets(': Unset.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text(withRepeatedMemName));
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(memNotificationOnDetailPageFinder)
                    as TextFormField)
                .initialValue,
            '12:16 AM',
          );
          await widgetTester.tap(clearIconFinder);
          await widgetTester.pump();

          expect(
            (widgetTester.widget(memNotificationOnDetailPageFinder)
                    as TextFormField)
                .initialValue,
            '',
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await Future.delayed(
            waitSideEffectDuration,
            () async {
              final memNotifications = (await db
                  .getTable(memNotificationTableDefinition.name)
                  .select(
                whereString: '${memIdFkDef.name} = ?',
                whereArgs: [withRepeatedMemId],
              ));
              await expectLater(memNotifications.length, 0);
            },
          );
        });
      });

      group(': After act started notification', () {
        testWidgets(': Set.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.add));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(okFinder);
          await widgetTester.pump();

          expect(
            (widgetTester.widget(
                        afterActStartedNotificationTimeOnDetailPageFinder)
                    as TextFormField)
                .initialValue,
            '1 h 0 m',
          );

          const enteringMemNotificationMessageText =
              '$_scenarioName: After act started notification: Set - mem notification message - entering';
          await widgetTester.enterText(
            afterActStartedNotificationMessageOnDetailPageFinder,
            enteringMemNotificationMessageText,
          );
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await Future.delayed(
            waitSideEffectDuration,
            () async {
              late final Map<String, dynamic> inserted;

              await expectLater(
                inserted = (await db
                        .getTable(memNotificationTableDefinition.name)
                        .select(
                  whereString: '${memIdFkDef.name} = ?',
                  whereArgs: [insertedMemId],
                ))
                    .single,
                isNotNull,
              );
              await expectLater(
                [
                  inserted[memIdFkDef.name],
                  inserted[timeColDef.name],
                  inserted[memNotificationTypeColDef.name],
                  // FIXME
                  inserted[memNotificationMessageColDef.name],
                  inserted[createdAtColDef.name],
                  inserted[updatedAtColDef.name],
                  inserted[archivedAtColDef.name],
                ],
                [
                  insertedMemId,
                  3600,
                  MemNotificationType.afterActStarted.name,
                  enteringMemNotificationMessageText,
                  isNotNull,
                  isNull,
                  isNull,
                ],
              );
            },
          );
        });

        testWidgets(': Unset.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.add));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(okFinder);
          await widgetTester.pump();

          await widgetTester.tap(find.byIcon(Icons.clear));
          await widgetTester.pump();

          expect(
            (widgetTester.widget(
                        afterActStartedNotificationTimeOnDetailPageFinder)
                    as TextFormField)
                .initialValue,
            '',
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await Future.delayed(
            waitSideEffectDuration,
            () async {
              await expectLater(
                (await db.getTable(memNotificationTableDefinition.name).select(
                  whereString: '${memIdFkDef.name} = ?',
                  whereArgs: [insertedMemId],
                )),
                isEmpty,
              );
            },
          );
        });
      });
    });
