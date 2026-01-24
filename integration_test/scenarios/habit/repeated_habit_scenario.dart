import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/framework/date_and_time/time_of_day_view.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mem_notifications/mem_notifications_view.dart';
import 'package:mem/features/mem_notifications/mem_repeated_notification_view.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = 'Repeated habit scenario';

void main() => group(': $_name', () {
      late final DriftDatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const baseMemName = "$_name - mem - name";
      const insertedMemName = "$baseMemName - inserted";
      const insertedMemName2 = "$insertedMemName - 2";

      final now = DateTime.now();

      late int insertedMemId;

      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        insertedMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemName,
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: insertedMemId,
          defColMemNotificationsType.name: MemNotificationType.repeat.name,
          defColMemNotificationsTime.name: 2,
          defColMemNotificationsMessage.name: "never",
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: insertedMemId,
          defColMemNotificationsType.name:
              MemNotificationType.repeatByNDay.name,
          defColMemNotificationsTime.name: 1,
          defColMemNotificationsMessage.name: "never",
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableActs, {
          defFkActsMemId.name: insertedMemId,
          defColActsStart.name: now.toIso8601String(),
          defColActsStartIsAllDay.name: 0,
          defColActsEnd.name: now.toIso8601String(),
          defColActsEndIsAllDay.name: 0,
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemName2,
          defColMemsStartOn.name: now.toIso8601String(),
          defColCreatedAt.name: zeroDate
        });
      });

      group('show', () {
        testWidgets('on new.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          expect(
              widgetTester
                  .widget<Text>(find.descendant(
                      of: find.byKey(keyMemNotificationsView),
                      matching: find.byType(Text)))
                  .data,
              l10n.noNotifications);
          final notificationAddFinder = find.descendant(
              of: find.byKey(keyMemNotificationsView),
              matching: find.byIcon(Icons.notification_add));
          expect(notificationAddFinder, findsOneWidget);

          await widgetTester.dragUntilVisible(notificationAddFinder,
              find.byType(SingleChildScrollView), const Offset(0, 50));
          await widgetTester.tap(notificationAddFinder);
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          expect(
              widgetTester
                  .widget<TimeOfDayTextFormField>(find.descendant(
                      of: find.byKey(keyMemRepeatedNotification),
                      matching: find.byType(TimeOfDayTextFormField)))
                  .timeOfDay,
              defaultStartOfDay);
          expect(
              find.descendant(
                  of: find.byKey(keyMemRepeatedNotification),
                  matching: find.byIcon(Icons.clear)),
              findsNothing);
        });

        // testWidgets('Saved.', (widgetTester) async {
        //   const repeatText = "12:00 AM";

        //   await runApplication();
        //   await widgetTester.pumpAndSettle();

        //   expect(find.text(repeatText), findsOneWidget);

        //   await widgetTester.tap(find.text(insertedMemName));
        //   await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //   expect(
        //     widgetTester
        //         .widget<Text>(
        //           find
        //               .descendant(
        //                 of: find.byKey(keyMemNotificationsView),
        //                 matching: find.byType(Text),
        //               )
        //               .at(0),
        //         )
        //         .data,
        //     repeatText,
        //   );

        //   await widgetTester.tap(find.descendant(
        //       of: find.byKey(keyMemNotificationsView),
        //       matching: find.byIcon(Icons.edit)));
        //   await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //   expect(
        //       widgetTester
        //           .widget<TimeOfDayTextFormField>(find.descendant(
        //               of: find.byKey(keyMemRepeatedNotification),
        //               matching: find.byType(TimeOfDayTextFormField)))
        //           .timeOfDay,
        //       defaultStartOfDay);
        //   expect(
        //       find.descendant(
        //           of: find.byKey(keyMemRepeatedNotification),
        //           matching: find.byIcon(Icons.clear)),
        //       findsOneWidget);
        // });
      });

      group(': save', () {
        setUp(() async {
          await dbA.insert(defTableActs, {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: zeroDate,
            defColActsStartIsAllDay.name: 0,
            defColCreatedAt.name: zeroDate
          });
        });

        testWidgets(': create.', (widgetTester) async {
          widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
          widgetTester
              .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);

          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();
          const enteringMemName = "$baseMemName - entering";
          await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);

          final notificationAddFinder = find.descendant(
              of: find.byKey(keyMemNotificationsView),
              matching: find.byIcon(Icons.notification_add));
          await widgetTester.dragUntilVisible(notificationAddFinder,
              find.byType(SingleChildScrollView), const Offset(0, 50));
          await widgetTester.tap(notificationAddFinder);
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          await widgetTester.tap(timeIconFinder);
          await widgetTester.pump();

          await widgetTester.tap(okFinder);
          await widgetTester.pump();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byKey(keySaveMemFab));
          await widgetTester.pumpAndSettle();

          final savedMem = (await dbA.select(defTableMems,
                  condition: Equals(defColMemsName, enteringMemName)))
              .single;
          final savedMemNotifications = await dbA.select(
              defTableMemNotifications,
              condition: Equals(defFkMemNotificationsMemId, savedMem[defPkId.name]));
          final repeat = savedMemNotifications.singleWhere((e) =>
              e[defColMemNotificationsType.name] ==
              MemNotificationType.repeat.name);
          expect(repeat[defColMemNotificationsTime.name], 0);
        });

        // testWidgets(": update.", (widgetTester) async {
        //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
        //   widgetTester
        //       .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);

        //   await runApplication();
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(find.text(insertedMemName));
        //   await widgetTester.pumpAndSettle();

        //   final notificationAddFinder = find.descendant(
        //       of: find.byKey(keyMemNotificationsView),
        //       matching: find.byIcon(Icons.edit));
        //   await widgetTester.dragUntilVisible(notificationAddFinder,
        //       find.byType(SingleChildScrollView), const Offset(0, 50));
        //   await widgetTester.tap(notificationAddFinder);
        //   await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //   await widgetTester.tap(find.descendant(
        //       of: find.byKey(keyMemRepeatedNotification),
        //       matching: find.byIcon(Icons.clear)));
        //   await widgetTester.pump();

        //   await widgetTester.tap(timeIconFinder);
        //   await widgetTester.pump();
        //   await widgetTester.tap(okFinder);
        //   await widgetTester.pump();

        //   await widgetTester.pageBack();
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(find.byKey(keySaveMemFab));
        //   await widgetTester.pump(waitSideEffectDuration);

        //   final savedMemId = (await dbA.select(defTableMems,
        //           where: "${defColMemsName.name} = ?",
        //           whereArgs: [insertedMemName]))
        //       .single[defPkId.name];
        //   final savedMemNotifications = (await dbA.select(
        //       defTableMemNotifications,
        //       where: "${defFkMemNotificationsMemId.name} = ?",
        //       whereArgs: [savedMemId],
        //       orderBy: "id ASC"));
        //   expect(savedMemNotifications, hasLength(2));
        //   expect(savedMemNotifications[0][defColMemNotificationsType.name],
        //       MemNotificationType.repeat.name);
        //   expect(savedMemNotifications[0][defColMemNotificationsTime.name], 0);
        //   expect(savedMemNotifications[1][defColMemNotificationsType.name],
        //       MemNotificationType.repeatByNDay.name);
        //   expect(savedMemNotifications[1][defColMemNotificationsTime.name], 1);
        // });
      });
    });
