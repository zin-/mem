import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/mems/detail/notifications/mem_repeated_notification_view.dart';
import 'package:mem/values/constants.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = 'Repeated habit scenario';

void main() => group(
      _name,
      () {
        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemName = "$_name - inserted - mem - name";
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
              defColMemNotificationsType.name: MemNotificationType.repeat.name,
              defColMemNotificationsTime.name: 1,
              defColMemNotificationsMessage.name: "never",
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        group(": Show", () {
          testWidgets(
            ": on new.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(newMemFabFinder);
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                widgetTester
                    .widget<Text>(
                      find.descendant(
                        of: find.byKey(keyMemNotificationsView),
                        matching: find.byType(Text),
                      ),
                    )
                    .data,
                l10n.noNotifications,
              );
              final notificationAddFinder = find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.notification_add),
              );
              expect(
                notificationAddFinder,
                findsOneWidget,
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

              expect(
                widgetTester
                    .widget<TimeOfDayTextFormField>(
                      find.descendant(
                          of: find.byKey(keyMemRepeatedNotification),
                          matching: find.byType(TimeOfDayTextFormField)),
                    )
                    .timeOfDay,
                null,
              );
              expect(
                find.descendant(
                    of: find.byKey(keyMemRepeatedNotification),
                    matching: find.byIcon(Icons.clear)),
                findsNothing,
              );
            },
          );

          testWidgets(
            ": on saved.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              expect(find.byType(Checkbox), findsNothing);

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
                "12:00 AM every day",
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
                    .widget<TimeOfDayTextFormField>(
                      find.descendant(
                        of: find.byKey(keyMemRepeatedNotification),
                        matching: find.byType(TimeOfDayTextFormField),
                      ),
                    )
                    .timeOfDay,
                defaultStartOfDay,
              );
              expect(
                find.descendant(
                    of: find.byKey(keyMemRepeatedNotification),
                    matching: find.byIcon(Icons.clear)),
                findsOneWidget,
              );
            },
          );
        });

        group(": Save", () {
          testWidgets(
            ": create.",
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

              final pickTime = TimeOfDay.now();
              await widgetTester.tap(timeIconFinder);
              await widgetTester.pump();

              await widgetTester.tap(okFinder);
              await widgetTester.pump();

              await widgetTester.pageBack();
              await widgetTester.pumpAndSettle();
              const enteringMemName =
                  "$_name: Save: create - entering - mem name";
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
                where: "${defFkMemNotificationsMemId.name} = ?",
                whereArgs: [savedMem[defPkId.name]],
              ))
                  .single;
              expect(
                savedMemNotification[defColMemNotificationsTime.name],
                (pickTime.hour * 60 + pickTime.minute) * 60,
              );
            },
          );

          testWidgets(
            ": update.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle();

              final notificationAddFinder = find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.edit),
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

              await widgetTester.tap(
                find.descendant(
                  of: find.byKey(keyMemRepeatedNotification),
                  matching: find.byIcon(Icons.clear),
                ),
              );
              await widgetTester.pump();

              final pickTime = TimeOfDay.now();
              await widgetTester.tap(timeIconFinder);
              await widgetTester.pump();
              await widgetTester.tap(okFinder);
              await widgetTester.pump();

              await widgetTester.pageBack();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.byKey(keySaveMemFab));
              await widgetTester.pump(waitSideEffectDuration);

              final savedMem = (await dbA.select(
                defTableMems,
                where: "${defColMemsName.name} = ?",
                whereArgs: [insertedMemName],
              ))
                  .single;
              final savedMemNotification = (await dbA.select(
                defTableMemNotifications,
                where: "${defFkMemNotificationsMemId.name} = ?",
                whereArgs: [savedMem[defPkId.name]],
              ))
                  .single;
              expect(
                savedMemNotification[defColMemNotificationsTime.name],
                (pickTime.hour * 60 + pickTime.minute) * 60,
              );
            },
          );
        });
      },
    );
