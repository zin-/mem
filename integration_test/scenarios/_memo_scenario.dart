import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  LogServiceV2.initialize(Level.verbose);

  DatabaseManager(onTest: true);

  setUp(() async {
    await clearDatabase();
  });

  testMemoScenario();
}

void testMemoScenario() => group(
      'Memo scenario',
      () {
        group(': V2', () {
          const savedMemName = 'Memo scenario: V2: saved mem name';

          setUp(() async {
            final memTable =
                (await DatabaseManager(onTest: true).open(databaseDefinition))
                    .getTable(memTableDefinition.name);

            await memTable.insert({
              defMemName.name: savedMemName,
              createdAtColumnName: DateTime.now(),
            });
          });

          testWidgets(
            ': List.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              expect(find.text(savedMemName), findsOneWidget);
            },
          );

          group(': Save', () {
            testWidgets(
              ': Create.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();

                expect(find.text(savedMemName), findsNothing);
                expect(find.text('Name'), findsOneWidget);
                const enteringMemNameText =
                    'Memo scenario: Save: create. entering mem name';
                const enteringMemMemoText =
                    'Memo scenario: Save: create. entering mem memo';
                await widgetTester.enterText(
                  memNameTextFormFieldFinder,
                  enteringMemNameText,
                );
                await widgetTester.enterText(
                  memMemoTextFormFieldFinder,
                  enteringMemMemoText,
                );
                await widgetTester.tap(saveMemFabFinder);
                await widgetTester.pumpAndSettle();

                const saveSuccessText = 'Save success. $enteringMemNameText';
                expect(
                  find.text(saveSuccessText),
                  findsOneWidget,
                );
                await widgetTester.pumpAndSettle(defaultDismissDuration);

                expect(
                  find.text(saveSuccessText),
                  findsNothing,
                );
                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle();

                expect(find.text(savedMemName), findsOneWidget);
                expect(find.text(enteringMemNameText), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsNothing);
                await widgetTester.tap(find.text(enteringMemNameText));
                await widgetTester.pumpAndSettle();

                expect(find.text(savedMemName), findsNothing);
                expect(
                  memNameTextFormField(widgetTester).initialValue,
                  enteringMemNameText,
                );
                expect(
                  (widgetTester.widget(
                    memMemoTextFormFieldFinder,
                  ) as TextFormField)
                      .initialValue,
                  enteringMemMemoText,
                );
              },
            );
          });
        });

        testWidgets(
          ': update saved Mem',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await runApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            const enteringMemName = 'entering mem name';
            const enteringMemMemo = 'entering mem memo';

            // FIXME 文字入力が動作しない場合がある
            //  改善しようとしたが、`pump`や`pumpAndSettle`を前後に追加するだけでは改善しなかった
            //    https://github.com/zin-/mem/issues/133
            // プロダクションコードの方に問題がある可能性があるので、後続のリファクタリングと同時に解決を目指す
            await widgetTester.enterText(
                memNameTextFormFieldFinder, enteringMemName);
            await widgetTester.enterText(
                memMemoTextFormFieldFinder, enteringMemMemo);

            await widgetTester.tap(saveMemFabFinder);
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();
            await widgetTester.pump();

            expect(find.text(enteringMemName), findsOneWidget);
            expect(find.text(enteringMemMemo), findsNothing);
            expect(find.text(savedMemName), findsNothing);
          },
        );

        testWidgets(
          ': archive saved Mem',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await runApplication(languageCode: 'en');
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
        );

        testWidgets(
          ': unarchive archived Mem',
          (widgetTester) async {
            const savedMemName = 'archived mem name';
            const savedMemMemo = 'archived mem memo';
            await prepareSavedData(savedMemName, savedMemMemo,
                isArchived: true);

            await runApplication(languageCode: 'en');
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
        );

        testWidgets(
          ': remove saved Mem',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            const savedMemMemo = 'saved mem memo';
            await prepareSavedData(savedMemName, savedMemMemo);

            await runApplication(languageCode: 'en');
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
        );

        testWidgets(
          'MemItem is nothing',
          (widgetTester) async {
            const savedMemName = 'saved mem name';
            final database =
                await DatabaseManager(onTest: true).open(databaseDefinition);
            final memTable = database.getTable(memTableDefinition.name);
            await memTable.insert({
              defMemName.name: savedMemName,
              createdAtColumnName: DateTime.now(),
              archivedAtColumnName: null,
            });

            await runApplication(languageCode: 'en');
            await widgetTester.pumpAndSettle(defaultDuration);

            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle(defaultDuration);

            expect(find.text(savedMemName), findsOneWidget);
            expect(
              widgetTester.widgetList(find.byType(TextFormField)).length,
              4,
            );
          },
        );
      },
    );
