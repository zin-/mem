import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/mem_notifications_view.dart';

import '../helpers.dart';

void main() {
  testRepeatedHabitScenario();
}

const _scenarioName = 'Repeated habit scenario';

void testRepeatedHabitScenario() => group(
      ": $_scenarioName",
      () {
        group(": Show", () {
          late final DatabaseAccessor dbA;
          setUpAll(() async {
            dbA = await openTestDatabase(databaseDefinition);
          });

          const insertedMemName = "$_scenarioName - inserted - mem - name";
          late int insertedMemId;

          setUp(() async {
            await clearAllTestDatabaseRows(databaseDefinition);

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
          });

          testWidgets(
            ": on new.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(newMemFabFinder);
              await widgetTester.pumpAndSettle();

              expect(
                widgetTester
                    .widget<Text>(
                      find.descendant(
                        of: find.byKey(keyMemNotificationsView),
                        matching: find.byType(Text),
                      ),
                    )
                    .data,
                l10n.no_notifications,
              );
              expect(
                find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.notification_add)),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            ": on saved.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle();

              expect(
                widgetTester
                    .widget<Text>(
                      find.descendant(
                          of: find.byKey(keyMemNotificationsView),
                          matching: find.byType(Text)),
                    )
                    .data,
                "12:00 AM every day",
              );
              expect(
                find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.edit)),
                findsOneWidget,
              );
            },
          );
        });
      },
    );
