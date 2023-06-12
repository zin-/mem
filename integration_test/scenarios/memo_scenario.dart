import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  LogServiceV2.initialize(Level.verbose);

  testMemoScenario();
}

void testMemoScenario() => group(
      'Memo scenario',
      () {
        group(': V2', () {
          const savedMemName = 'Memo scenario: V2: saved mem name';
          late final Database db;

          setUpAll(() async {
            db = await DatabaseManager(onTest: true).open(databaseDefinition);
          });
          setUp(() async {
            final memTable = db.getTable(memTableDefinition.name);

            await memTable.insert({
              defMemName.name: savedMemName,
              createdAtColumnName: DateTime.now(),
            });
          });
          tearDown(() async {
            final memItemTable = db.getTable(memItemTableDefinition.name);
            final memTable = db.getTable(memTableDefinition.name);

            await memItemTable.delete();
            await memTable.delete();
          });
          tearDownAll(() async {
            await DatabaseManager(onTest: true).delete(databaseDefinition.name);
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

            testWidgets(
              ': Update.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(savedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(savedMemName));
                const enteringMemNameText =
                    'Memo scenario: Save: Update. entering mem name';
                const enteringMemMemoText =
                    'Memo scenario: Save: Update. entering mem memo';
                await widgetTester.enterText(
                  memNameTextFormFieldFinder,
                  enteringMemNameText,
                );
                await widgetTester.enterText(
                  memMemoTextFormFieldFinder,
                  enteringMemMemoText,
                );
                await widgetTester.pumpAndSettle();

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

                expect(find.text(savedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
                await widgetTester.tap(find.text(enteringMemNameText));
                await widgetTester.pumpAndSettle();

                expect(find.text(savedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsOneWidget);
              },
            );
          });
        });

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

            await widgetTester.tap(find.text('Undo'));
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsOneWidget);
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
