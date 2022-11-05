import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/log_repository.dart';
import 'package:mem/listAndDetails/mem_notify_at.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  initializeLogger(Level.verbose);
  DatabaseManager(onTest: true);

  testMemoScenario();
}

void testMemoScenario() => group(
      'Memo scenario',
      () {
        setUp(() async {
          await clearDatabase();
        });

        testWidgets(
          ': create new Mem',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            const enteringMemName = 'entering mem name: create new Mem';
            await widgetTester.enterText(
              memNameTextFormFieldFinder,
              enteringMemName,
            );
            await widgetTester.pump();

            await widgetTester.tap(showDatePickerIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(okFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(allDaySwitchFinder);
            await widgetTester.pumpAndSettle();

            final now = DateTime.now();
            await widgetTester.tap(showTimePickerIconFinder);
            await widgetTester.pumpAndSettle();
            // FIXME 特定の時間を選択する
            // 現状だと現在時刻が選択され、タイミングによってはテストが失敗する
            await widgetTester.tap(okFinder);
            await widgetTester.pumpAndSettle();

            const enteringMemMemo = 'entering mem memo: create new Mem';
            await widgetTester.enterText(
              memMemoTextFormFieldFinder,
              enteringMemMemo,
            );
            await widgetTester.pump();

            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.pageBack();
            await widgetTester.pump();

            expect(find.text(enteringMemName), findsOneWidget);
            expect(find.text(enteringMemMemo), findsNothing);
            // FIXME シナリオテストでここまでしないといけないのはなんとかしたい
            try {
              expect(
                widgetTester
                    .widget<MemNotifyAtText>(memNotifyAtTextFinder)
                    .data,
                DateFormat.yMd('en').add_Hm().format(now),
              );
            } catch (e) {
              warn(e);
              expect(
                widgetTester
                    .widget<MemNotifyAtText>(memNotifyAtTextFinder)
                    .data,
                DateFormat.yMd('en')
                    .add_Hm()
                    .format(now.subtract(const Duration(minutes: 1))),
              );
            }
          },
          tags: TestSize.medium,
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

            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.pageBack();
            // FIXME 2秒は長すぎる。何が原因で見つからないのか分からないので一旦時間を伸ばしてみた
            await widgetTester.pumpAndSettle(const Duration(seconds: 2));

            expect(find.text(enteringMemName), findsOneWidget);
            expect(find.text(enteringMemMemo), findsNothing);
            expect(find.text(savedMemName), findsNothing);
          },
          tags: TestSize.medium,
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
          tags: TestSize.medium,
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
          tags: TestSize.medium,
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
          tags: TestSize.medium,
        );
      },
    );
