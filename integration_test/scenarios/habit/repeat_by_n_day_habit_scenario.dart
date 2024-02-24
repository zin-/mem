import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/mems/detail/notifications/mem_repeat_by_n_day_notification_view.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

void main() {
  testRepeatByNDayHabitScenario();
}

const _scenarioName = 'Repeat by n day habit scenario';

void testRepeatByNDayHabitScenario() => group(
      ": $_scenarioName",
      () {
        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });
        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);
        });

        group(": Show", () {
          const insertedMemName = "$_scenarioName - mem name - inserted";
          const insertedMemRepeatByNDay = 2;

          late int insertedMemId;

          setUp(() async {
            insertedMemId = await dbA.insert(
              defTableMems,
              {
                defColMemsName.name: insertedMemName,
                defColCreatedAt.name: zeroDate,
              },
            );
            await dbA.insert(
              defTableMemNotifications,
              {
                defFkMemNotificationsMemId.name: insertedMemId,
                defColMemNotificationsType.name:
                    MemNotificationType.repeat.name,
                defColMemNotificationsTime.name: 1,
                defColMemNotificationsMessage.name: "never",
                defColCreatedAt.name: zeroDate,
              },
            );
            await dbA.insert(
              defTableMemNotifications,
              {
                defFkMemNotificationsMemId.name: insertedMemId,
                defColMemNotificationsType.name:
                    MemNotificationType.repeatByNDay.name,
                defColMemNotificationsTime.name: insertedMemRepeatByNDay,
                defColMemNotificationsMessage.name: "never",
                defColCreatedAt.name: zeroDate,
              },
            );
          });

          testWidgets(
            ": on saved.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                widgetTester
                    .widget<Text>(
                      find.descendant(
                          of: find.byKey(keyMemNotificationsView),
                          matching: find.byType(Text)),
                    )
                    .data,
                "12:00 AM every $insertedMemRepeatByNDay days",
              );

              await widgetTester.tap(
                find.descendant(
                  of: find.byKey(keyMemNotificationsView),
                  matching: find.byIcon(Icons.edit),
                ),
              );
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                widgetTester
                    .widget<TextFormField>(
                      find.descendant(
                        of: find.byKey(keyMemRepeatByNDayNotification),
                        matching: find.byType(TextFormField),
                      ),
                    )
                    .initialValue,
                insertedMemRepeatByNDay.toString(),
              );
            },
          );
        });

        testWidgets(
          ": Save",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            final notificationAddFinder = find.descendant(
              of: find.byKey(keyMemNotificationsView),
              matching: find.byIcon(Icons.notification_add),
            );
            await widgetTester.dragUntilVisible(
              notificationAddFinder,
              find.byType(SingleChildScrollView),
              const Offset(0, 50),
            );
            await widgetTester.tap(
              notificationAddFinder,
            );
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(timeIconFinder);
            await widgetTester.pump();
            await widgetTester.tap(okFinder);
            await widgetTester.pump();

            const enteringNDay = 3;
            await widgetTester.enterText(
              find.descendant(
                  of: find.byKey(keyMemRepeatByNDayNotification),
                  matching: find.byType(TextFormField)),
              enteringNDay.toString(),
            );

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();
            const enteringMemName =
                "$_scenarioName: Save - entering - mem name";
            await widgetTester.enterText(
              find.byKey(keyMemName),
              enteringMemName,
            );
            await widgetTester.tap(find.byKey(keySaveMemFab));
            await widgetTester.pump(waitSideEffectDuration);

            final savedMem = (await dbA.select(
              defTableMems,
              where: "${defColMemsName.name} = ?",
              whereArgs: [enteringMemName],
            ))
                .single;
            final savedMemNotification = (await dbA.select(
              defTableMemNotifications,
              where: "${defFkMemNotificationsMemId.name} = ?"
                  " AND ${defColMemNotificationsType.name} = ?"
                  " AND ${defColMemNotificationsTime.name} = ?",
              whereArgs: [
                savedMem[defPkId.name],
                MemNotificationType.repeatByNDay.name,
                enteringNDay,
              ],
            ))
                .single;
            expect(
              savedMemNotification[defColMemNotificationsTime.name],
              enteringNDay,
            );
          },
        );
      },
    );
