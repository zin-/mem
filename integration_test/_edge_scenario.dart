import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/database_tuple_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  testEdgeScenario();
}

void testEdgeScenario() => group(
      'Todo scenario',
      () {
        setUp(() async => await clearDatabase());

        group(
          'Edge scenario',
          () {
            testWidgets(
              'MemItem is nothing',
              (widgetTester) async {
                const savedMemName = 'saved mem name';
                final database =
                    await DatabaseManager().open(app.databaseDefinition);
                final memTable = database.getTable(memTableDefinition.name);
                await memTable.insert({
                  memNameColumnName: savedMemName,
                  createdAtColumnName: DateTime.now(),
                  archivedAtColumnName: null,
                });

                await app.main(languageCode: 'en');
                await widgetTester.pumpAndSettle(defaultDuration);

                await widgetTester.tap(find.text(savedMemName));
                await widgetTester.pumpAndSettle(defaultDuration);

                expect(find.text(savedMemName), findsOneWidget);
                expect(
                    widgetTester.widgetList(find.byType(TextFormField)).length,
                    3);
              },
              tags: 'Medium',
            );
          },
        );
      },
    );
