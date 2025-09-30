import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/mem_name.dart';
// import 'package:mem/framework/date_and_time/time_text_form_field.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mem_notifications/after_act_started_notification_view.dart';
import 'package:mem/features/mem_notifications/mem_notifications_view.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = 'After act started habit scenario';

void main() => group(
      _name,
      () {
        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemName = "$_name - inserted - mem - name";
        const secondsOfTime = 1 * 60;

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
                  MemNotificationType.afterActStarted.name,
              defColMemNotificationsTime.name: secondsOfTime,
              defColMemNotificationsMessage.name: "never",
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        // testWidgets(
        //   'Show on saved.',
        //   (widgetTester) async {
        //     widgetTester.ignoreMockMethodCallHandler(
        //         MethodChannelMock.flutterLocalNotifications);

        //     await runApplication();
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(find.text(insertedMemName));
        //     await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //     expect(
        //       widgetTester
        //           .widget<Text>(
        //             find.descendant(
        //                 of: find.byKey(keyMemNotificationsView),
        //                 matching: find.byType(Text)),
        //           )
        //           .data,
        //       "00:01 after started",
        //     );

        //     await widgetTester.tap(
        //       find.descendant(
        //         of: find.byKey(keyMemNotificationsView),
        //         matching: find.byIcon(Icons.edit),
        //       ),
        //     );
        //     await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //     expect(
        //       widgetTester
        //           .widget<TimeTextFormField>(
        //             find.descendant(
        //               of: find.byKey(keyMemAfterActStartedNotification),
        //               matching: find.byType(TimeTextFormField),
        //             ),
        //           )
        //           .secondsOfTime,
        //       secondsOfTime,
        //     );
        //     expect(
        //       find.descendant(
        //           of: find.byKey(keyMemAfterActStartedNotification),
        //           matching: find.byIcon(Icons.clear)),
        //       findsOneWidget,
        //     );
        //   },
        // );

        testWidgets(
          'Save.',
          (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.flutterLocalNotifications);
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.permissionHandler);

            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            final notificationAddFinder = find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.notification_add));
            await widgetTester.dragUntilVisible(notificationAddFinder,
                find.byType(SingleChildScrollView), const Offset(0, 50));
            await widgetTester.tap(notificationAddFinder);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(find.descendant(
                of: find.byKey(keyMemAfterActStartedNotification),
                matching: find.byIcon(Icons.add)));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(okFinder);
            await widgetTester.pumpAndSettle();

            const enteringMemNotificationMessage =
                "$_name - entering - mem notification message";
            await widgetTester.enterText(
                find
                    .descendant(
                        of: find.byKey(keyMemAfterActStartedNotification),
                        matching: find.byType(TextFormField))
                    .at(1),
                enteringMemNotificationMessage);
            await widgetTester.pump();

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            expect(
                widgetTester
                    .widget<Text>(find.descendant(
                        of: find.byKey(keyMemNotificationsView),
                        matching: find.byType(Text)))
                    .data,
                "01:00 after started");

            const enteringMemName = "$_name: Save - entering - mem name";
            await widgetTester.enterText(
                find.byKey(keyMemName), enteringMemName);

            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.flutterLocalNotifications);

            await widgetTester.tap(find.byKey(keySaveMemFab));
            await widgetTester.pump(waitSideEffectDuration);

            final savedMem = (await dbA.select(defTableMems,
                    where: "${defColMemsName.name} = ?",
                    whereArgs: [enteringMemName]))
                .single;
            final savedMemNotifications = (await dbA.select(
                defTableMemNotifications,
                where: "${defFkMemNotificationsMemId.name} = ?",
                whereArgs: [savedMem[defPkId.name]]));
            final afterActStarted = savedMemNotifications.singleWhere((e) =>
                e[defColMemNotificationsType.name] ==
                NotificationType.afterActStarted.name);
            expect(afterActStarted[defColMemNotificationsTime.name],
                (1 * 60) * 60);
            expect(afterActStarted[defColMemNotificationsMessage.name],
                enteringMemNotificationMessage);
          },
        );

        // testWidgets(
        //   ": clear.",
        //   (widgetTester) async {
        //     widgetTester.ignoreMockMethodCallHandler(
        //         MethodChannelMock.flutterLocalNotifications);

        //     await runApplication();
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(find.text(insertedMemName));
        //     await widgetTester.pumpAndSettle(defaultTransitionDuration);
        //     await widgetTester.tap(
        //       find.descendant(
        //         of: find.byKey(keyMemNotificationsView),
        //         matching: find.byIcon(Icons.edit),
        //       ),
        //     );
        //     await widgetTester.pumpAndSettle();

        //     await widgetTester.tap(
        //       find.descendant(
        //         of: find.byKey(keyMemAfterActStartedNotification),
        //         matching: find.byIcon(Icons.clear),
        //       ),
        //     );
        //     await widgetTester.pump();

        //     expect(
        //       widgetTester
        //           .widget<TimeTextFormField>(
        //             find.descendant(
        //               of: find.byKey(keyMemAfterActStartedNotification),
        //               matching: find.byType(TimeTextFormField),
        //             ),
        //           )
        //           .secondsOfTime,
        //       null,
        //     );
        //     expect(
        //       find.descendant(
        //           of: find.byKey(keyMemAfterActStartedNotification),
        //           matching: find.byIcon(Icons.clear)),
        //       findsNothing,
        //     );
        //   },
        // );

        testWidgets(
          'start act.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(startIconFinder);

            await widgetTester.pump();
            await widgetTester.pumpAndSettle();

            expect(startIconFinder, findsNothing);
          },
        );
      },
    );
