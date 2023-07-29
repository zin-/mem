import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mem_notifications.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActScenario();
}

const _scenarioName = 'Act scenario';

void testActScenario() => group(': $_scenarioName', () {
      final showActPageIconFinder = find.byIcon(Icons.play_arrow);

      const insertedMemName = '$_scenarioName: saved mem name';

      late final Database db;
      late final int insertedMemId;

      setUpAll(() async {
        db = (await DatabaseManager(onTest: true).open(databaseDefinition));

        await resetDatabase(db);

        insertedMemId = await db.getTable(memTableDefinition.name).insert({
          defMemName.name: insertedMemName,
          createdAtColDef.name: DateTime.now(),
        });
        await db.getTable(memNotificationTableDefinition.name).insert({
          memIdFkDef.name: insertedMemId,
          timeColDef.name: 1,
          memNotificationTypeColDef.name:
              MemNotificationType.afterActStarted.name,
          memNotificationMessageColDef.name:
              '$_scenarioName: mem notification message',
          createdAtColDef.name: DateTime.now(),
        });
      });
      setUp(() async {
        await db.getTable(actTableDefinition.name).delete();
      });

      Future<void> showMemListPage(WidgetTester widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
      }

      group(': ActListPage', () {
        Future<void> showActListPage(WidgetTester widgetTester) async {
          await showMemListPage(widgetTester);

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showActPageIconFinder);
          await widgetTester.pumpAndSettle();
        }

        testWidgets(
          ': start & finish act.',
          (widgetTester) async {
            await showActListPage(widgetTester);

            expect(find.byIcon(Icons.stop), findsNothing);
            final startTime = DateTime.now();
            await widgetTester.tap(find.byIcon(Icons.play_arrow));
            await Future.delayed(defaultTransitionDuration);
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.play_arrow), findsNothing);
            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              dateText(startTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(2)) as Text).data,
              timeText(startTime),
            );
            final stopTime = DateTime.now();
            await widgetTester.tap(find.byIcon(Icons.stop));
            await Future.delayed(defaultTransitionDuration);
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              dateText(startTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(2)) as Text).data,
              timeText(startTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(4)) as Text).data,
              dateText(stopTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(6)) as Text).data,
              timeText(stopTime),
            );

            expect(find.byIcon(Icons.stop), findsNothing);
            final startTime2 = DateTime.now();
            await widgetTester.tap(find.byIcon(Icons.play_arrow));
            await Future.delayed(defaultTransitionDuration);
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              dateText(startTime2),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(2)) as Text).data,
              timeText(startTime2),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(4)) as Text).data,
              dateText(startTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(6)) as Text).data,
              timeText(startTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(8)) as Text).data,
              dateText(stopTime),
            );
            expect(
              (widgetTester.widget(find.byType(Text).at(10)) as Text).data,
              timeText(stopTime),
            );
          },
        );

        group(': Edit act', () {
          late DateTime now;

          setUp(() async {
            now = DateTime.now();

            await db.getTable(actTableDefinition.name).insert({
              fkDefMemId.name: insertedMemId,
              defActStart.name: now,
              defActStartIsAllDay.name: 0,
              createdAtColDef.name: now,
            });
            await db.getTable(actTableDefinition.name).insert({
              fkDefMemId.name: insertedMemId,
              defActStart.name: now,
              defActStartIsAllDay.name: 0,
              createdAtColDef.name: now,
            });
          });

          testWidgets(': save.', (widgetTester) async {
            await showActListPage(widgetTester);

            await widgetTester.longPress(
              find.text(dateText(now)).at(1),
            );
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byType(Switch).at(0));
            await widgetTester.tap(find.byType(Switch).at(1));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text('OK'));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.save_alt));
            await widgetTester.pumpAndSettle();

            final updatedActEnd =
                (await db.getTable(actTableDefinition.name).select(
              whereString: '${fkDefMemId.name} = ?',
              whereArgs: [insertedMemId],
            ))
                    .singleWhere((element) =>
                        element[updatedAtColDef.name] != null)[defActEnd.name];
            expect(find.text(dateText(now)), findsNWidgets(3));
            if (dateTimeText(now) == dateTimeText(updatedActEnd)) {
              expect(find.text(timeText(now)), findsNWidgets(3));
            } else {
              expect(find.text(timeText(now)), findsNWidgets(2));
              expect(find.text(timeText(updatedActEnd)), findsOneWidget);
            }
          });

          testWidgets(': delete.', (widgetTester) async {
            await showActListPage(widgetTester);

            expect(find.text(dateText(now)), findsNWidgets(2));
            expect(find.text(timeText(now)), findsNWidgets(2));

            await widgetTester.longPress(
              find.text(dateText(now)).at(0),
            );
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.delete));
            await widgetTester.pumpAndSettle();

            expect(find.text(dateText(now)), findsOneWidget);
            expect(find.text(timeText(now)), findsOneWidget);
          });
        });
      });

      group(': MemListPage', () {
        const insertedMemName2 = '$insertedMemName - 2';

        setUpAll(() async {
          final memTable = db.getTable(memTableDefinition.name);

          await memTable.insert({
            defMemName.name: insertedMemName2,
            createdAtColDef.name: DateTime.now(),
          });
        });

        final startIconFinder = find.byIcon(Icons.play_arrow);
        final stopIconFinder = find.byIcon(Icons.stop);

        testWidgets(': start & finish act.', (widgetTester) async {
          await showMemListPage(widgetTester);

          expect(startIconFinder, findsNWidgets(2));
          expect(stopIconFinder, findsNothing);

          await widgetTester.tap(startIconFinder.at(1));
          await widgetTester.pump();

          expect(
            (widgetTester.widget(find.byType(Text).at(2)) as Text).data,
            '00:00:00',
          );
          expect(startIconFinder, findsOneWidget);
          expect(stopIconFinder, findsOneWidget);
          await widgetTester.pump(elapsePeriod);

          expect(find.text('00:00:00'), findsNothing);
          await widgetTester.tap(startIconFinder);
          await widgetTester.pumpAndSettle();

          expect(startIconFinder, findsNothing);
          expect(stopIconFinder, findsNWidgets(2));

          await widgetTester.tap(stopIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          expect(stopIconFinder, findsOneWidget);
          expect(startIconFinder, findsOneWidget);
        });
      });
    });
