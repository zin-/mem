import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logger/logger.dart';
import 'package:mem/database/database_factory.dart';

import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  testMemoScenario();
}

void testMemoScenario() => group(
      'Memo scenario',
      () {
        setUp(() async => await clearDatabase());

        testWidgets(
          ': create',
          (widgetTester) async {
            await pumpApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.byIcon(Icons.add));
            await widgetTester.pumpAndSettle(defaultDuration);

            const enteringMemName = 'entering mem name';
            const enteringMemMemo = 'entering mem memo';

            await widgetTester.enterText(
                memNameTextFormFieldFinder, enteringMemName);
            await widgetTester.enterText(
                memMemoTextFormFieldFinder, enteringMemMemo);

            await widgetTester.tap(saveFabFinder);
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(enteringMemName), findsOneWidget);
            expect(find.text(enteringMemMemo), findsNothing);
          },
          tags: 'Medium',
        );

        testWidgets(
          ': update',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await pumpApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            const enteringMemName = 'entering mem name';
            const enteringMemMemo = 'entering mem memo';

            await widgetTester.enterText(
                memNameTextFormFieldFinder, enteringMemName);
            await widgetTester.enterText(
                memMemoTextFormFieldFinder, enteringMemMemo);

            await widgetTester.tap(saveFabFinder);
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.pageBack();
            // FIXME 2秒は長すぎる。何が原因で見つからないのか分からないので一旦時間を伸ばしてみた
            await widgetTester.pumpAndSettle(const Duration(seconds: 2));

            expect(find.text(enteringMemName), findsOneWidget);
            expect(find.text(enteringMemMemo), findsNothing);
            expect(find.text(savedMemName), findsNothing);
          },
          tags: 'Medium',
        );

        testWidgets(
          ': archive',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await pumpApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.byIcon(Icons.archive));
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(
              find.descendant(
                of: find.byType(Text),
                matching: find.text(savedMemName),
              ),
              findsNothing,
            );

            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(findShowArchiveSwitch);
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(savedMemName), findsOneWidget);
          },
          tags: 'Medium',
        );

        testWidgets(
          ': unarchive',
          (widgetTester) async {
            const savedMemName = 'archived mem name';
            const savedMemMemo = 'archived mem memo';
            await prepareSavedData(savedMemName, savedMemMemo,
                isArchived: true);

            await pumpApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(findShowArchiveSwitch);
            await widgetTester.tap(findShowNotArchiveSwitch);
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.byIcon(Icons.unarchive));
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(savedMemName), findsNothing);

            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(findShowNotArchiveSwitch);
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(savedMemName), findsOneWidget);
          },
          tags: 'Medium',
        );

        testWidgets(
          ': remove',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await pumpApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.byIcon(Icons.more_vert),
              ),
            );
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(find.byIcon(Icons.delete));
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(find.text('OK'));
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(savedMemName), findsNothing);

            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle(defaultDuration);
            await widgetTester.tap(findShowArchiveSwitch);
            await widgetTester.pumpAndSettle(defaultDuration);
            await closeMemListFilter(widgetTester);

            expect(find.text(savedMemName), findsNothing);
          },
          tags: 'Medium',
        );
      },
    );
