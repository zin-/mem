import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mem_items.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/main.dart' as app;

import '../helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActScenario();
}

void testActScenario() => group(': Act scenario', () {
      final showActPageIconFinder = find.byIcon(Icons.play_arrow);

      const insertedMemName = 'Act scenario: saved mem name';

      late final Database db;
      late final int insertedMemId;

      setUpAll(() async {
        db = (await DatabaseManager(onTest: true).open(databaseDefinition));

        await db.getTable(memItemTableDefinition.name).delete();
        await db.getTable(actTableDefinition.name).delete();
        final memTable = db.getTable(memTableDefinition.name);
        await memTable.delete();

        insertedMemId = await memTable.insert({
          defMemName.name: insertedMemName,
          createdAtColDef.name: DateTime.now(),
        });
      });
      setUp(() async {
        await db.getTable(actTableDefinition.name).delete();
      });

      Future<void> showMemListPage(WidgetTester widgetTester) async {
        await app.main();
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
            await widgetTester.tap(find.byIcon(Icons.play_arrow));
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.play_arrow), findsNothing);
            final now = DateTime.now();
            expect(
              find.text(dateTimeText(now)),
              findsOneWidget,
            );

            await widgetTester.tap(find.byIcon(Icons.stop));
            await widgetTester.pumpAndSettle();

            expect(
              find.text(dateTimeText(now)),
              findsNWidgets(2),
            );

            expect(find.byIcon(Icons.stop), findsNothing);
            await widgetTester.tap(find.byIcon(Icons.play_arrow));
            await widgetTester.pumpAndSettle();

            expect(
              find.text(dateTimeText(now)),
              findsNWidgets(3),
            );
          },
        );

        group(': Edit act', () {
          late DateTime createdAt;

          setUp(() async {
            createdAt = DateTime.now();

            await db.getTable(actTableDefinition.name).insert({
              fkDefMemId.name: insertedMemId,
              defActStart.name: createdAt,
              defActStartIsAllDay.name: 0,
              createdAtColDef.name: createdAt,
            });
            await db.getTable(actTableDefinition.name).insert({
              fkDefMemId.name: insertedMemId,
              defActStart.name: createdAt,
              defActStartIsAllDay.name: 0,
              createdAtColDef.name: createdAt,
            });
          });

          testWidgets(': save.', (widgetTester) async {
            await showActListPage(widgetTester);

            await widgetTester.longPress(
              find.text(dateTimeText(createdAt)).at(1),
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
            if (dateTimeText(createdAt) == dateTimeText(updatedActEnd)) {
              expect(find.text(dateTimeText(createdAt)), findsNWidgets(3));
            } else {
              expect(find.text(dateTimeText(createdAt)), findsNWidgets(2));
              expect(find.text(dateTimeText(updatedActEnd)), findsOneWidget);
            }
          });

          testWidgets(': delete.', (widgetTester) async {
            await showActListPage(widgetTester);

            await widgetTester.longPress(
              find.text(dateTimeText(createdAt)).at(0),
            );
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.delete));
            await widgetTester.pumpAndSettle();

            expect(find.text(dateTimeText(createdAt)), findsOneWidget);
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
          await widgetTester.pumpAndSettle();

          expect(find.text('00:00:00'), findsOneWidget);
          expect(startIconFinder, findsOneWidget);
          expect(stopIconFinder, findsOneWidget);
          await widgetTester.pump(const Duration(seconds: 1));

          expect(find.text('00:00:00'), findsNothing);
          await widgetTester.tap(startIconFinder);
          await widgetTester.pumpAndSettle();

          expect(startIconFinder, findsNothing);
          expect(stopIconFinder, findsNWidgets(2));

          await widgetTester.tap(stopIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          expect(startIconFinder, findsOneWidget);
          expect(stopIconFinder, findsOneWidget);
        });
      });
    });
