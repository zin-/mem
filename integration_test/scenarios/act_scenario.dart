import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_entity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testActScenario();
}

void testActScenario() => group(': Act scenario', () {
      final showActPageIconFinder = find.byIcon(Icons.play_arrow);

      const savedMemName = 'Act scenario: saved mem name';

      late final Database db;
      late final int savedMemId;

      setUpAll(() async {
        db = (await DatabaseManager(onTest: true).open(app.databaseDefinition));
        final memTable = db.getTable(memTableDefinition.name);

        await memTable.delete();
        savedMemId = await memTable.insert({
          defMemName.name: savedMemName,
          createdAtColumnName: DateTime.now(),
        });
      });
      setUp(() async {
        await db.getTable(actTableDefinition.name).delete();
      });
      tearDownAll(() async {
        await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);
      });

      String dateTimeText(DateTime dateTime) {
        final hour =
            dateTime.hour < 10 ? '0${dateTime.hour}' : '${dateTime.hour}';
        final minute =
            dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
        return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute';
      }

      Future<void> showMemListPage(WidgetTester widgetTester) async {
        await app.main();
        await widgetTester.pumpAndSettle();
      }

      group(': ActListPage', () {
        Future<void> showActListPage(WidgetTester widgetTester) async {
          await showMemListPage(widgetTester);

          await widgetTester.tap(find.text(savedMemName));
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
              fkDefMemId.name: savedMemId,
              defActStart.name: createdAt,
              defActStartIsAllDay.name: 0,
              createdAtColumnName: createdAt,
            });
            await db.getTable(actTableDefinition.name).insert({
              fkDefMemId.name: savedMemId,
              defActStart.name: createdAt,
              defActStartIsAllDay.name: 0,
              createdAtColumnName: createdAt,
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

            expect(find.text(dateTimeText(createdAt)), findsNWidgets(3));
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
        const savedMemName2 = '$savedMemName - 2';

        setUpAll(() async {
          final memTable = db.getTable(memTableDefinition.name);

          await memTable.insert({
            defMemName.name: savedMemName2,
            createdAtColumnName: DateTime.now(),
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

          await widgetTester.tap(stopIconFinder.at(1));
          await widgetTester.pumpAndSettle();

          expect(startIconFinder, findsOneWidget);
          expect(stopIconFinder, findsOneWidget);
        });
      });
    });
