import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTodoScenario();
}

const _scenarioName = 'Todo scenario';

void testTodoScenario() => group(': $_scenarioName', () {
      LogService.initialize(
        Level.verbose,
        const bool.fromEnvironment('CICD', defaultValue: false),
      );

      const insertedMemName = '$_scenarioName - mem name - inserted';

      const undoneMemName = '$_scenarioName - mem name - inserted - undone';
      const doneMemName = '$_scenarioName - mem name - inserted - done';

      late final DatabaseAccessor dbA;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });
      int? insertedMemDoneId;
      setUp(() async {
        NotificationClient.resetSingleton();

        await clearAllTestDatabaseRows(databaseDefinition);

        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: undoneMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
        insertedMemDoneId = await dbA.insert(defTableMems, {
          defColMemsName.name: doneMemName,
          defColMemsDoneAt.name: zeroDate,
          defColCreatedAt.name: zeroDate,
        });
      });

      group(
        ": show",
        () {
          testWidgets(
            ": list: initial.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsOneWidget);
              expect(find.text(undoneMemName), findsOneWidget);
              expect(find.text(doneMemName), findsNothing);

              await widgetTester.tap(filterListIconFinder);
              await widgetTester.pumpAndSettle();

              expect(
                widgetTester.widget<Switch>(find.byType(Switch).at(2)).value,
                true,
              );
              expect(
                widgetTester.widget<Switch>(find.byType(Switch).at(3)).value,
                false,
              );
            },
          );
        },
      );

      group(': done & undone', () {
        testWidgets(
          ': MemDetailPage.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Checkbox));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(filterListIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(3));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Checkbox));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(filterListIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(2));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsNothing);
            expect(find.text(doneMemName), findsOneWidget);
          },
        );

        testWidgets(
          ': MemListPage.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(find.byType(Checkbox).at(0));
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(filterListIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(2));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(find.byType(Checkbox).at(1));
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(filterListIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(3));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsNothing);
            expect(find.text(doneMemName), findsOneWidget);
          },
        );
      });

      testWidgets(
        'not notify on done mem.',
        (widgetTester) async {
          int initializeCount = 0;
          int cancelCount = 0;
          widgetTester.setMockMethodCallHandler(
            MethodChannelMock.flutterLocalNotifications,
            [
              (message) async {
                expect(message.method, equals('initialize'));
                initializeCount++;
                return true;
              },
              ...AllMemNotificationsId.of(insertedMemDoneId!).map(
                (e) => (message) async {
                  expect(message.method, equals('cancel'));
                  expect(message.arguments['id'], equals(e));
                  cancelCount++;
                  return false;
                },
              ),
            ],
          );

          int alarmServiceStartCount = 0;
          int alarmCancelCount = 0;
          widgetTester
              .setMockMethodCallHandler(MethodChannelMock.androidAlarmManager, [
            (message) async {
              expect(message.method, equals('AlarmService.start'));
              expect(
                  message.arguments,
                  orderedEquals([
                    isNotNull,
                  ]));
              alarmServiceStartCount++;
              return true;
            },
            ...AllMemNotificationsId.of(insertedMemDoneId!).map(
              (e) => (message) async {
                expect(message.method, equals('Alarm.cancel'));
                expect(message.arguments, orderedEquals([equals(e)]));
                alarmCancelCount++;
                return false;
              },
            ),
          ]);

          await NotificationClient().show(
            NotificationType.startMem,
            insertedMemDoneId!,
          );

          if (defaultTargetPlatform == TargetPlatform.android) {
            expect(initializeCount, equals(1));
            expect(cancelCount, equals(6));
            expect(alarmServiceStartCount, equals(1));
            expect(alarmCancelCount, equals(6));
          } else {
            expect(initializeCount, equals(0));
            expect(cancelCount, equals(0));
            expect(alarmServiceStartCount, equals(0));
            expect(alarmCancelCount, equals(0));
          }

          widgetTester.clearAllMockMethodCallHandler();
        },
      );
    });
