import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testMemoScenario();
}

const scenarioName = 'Memo scenario';

void testMemoScenario() => group(
      ': $scenarioName',
      () {
        group(': V2', () {
          const insertedMemName = '$scenarioName - mem name - inserted';
          const insertedMemMemo = '$scenarioName - mem memo - inserted';
          late final Database db;

          setUpAll(() async {
            db = await DatabaseManager(onTest: true).open(databaseDefinition);
          });
          setUp(() async {
            final memItemTable = db.getTable(memItemTableDefinition.name);
            final memTable = db.getTable(memTableDefinition.name);

            await memItemTable.delete();
            await memTable.delete();

            final insertedMemId =
                await db.getTable(memTableDefinition.name).insert({
              defMemName.name: insertedMemName,
              createdAtColumnName: DateTime.now(),
            });
            await db.getTable(memItemTableDefinition.name).insert({
              memIdColumnName: insertedMemId,
              memItemTypeColumnName: MemItemType.memo.name,
              memItemValueColumnName: insertedMemMemo,
              createdAtColumnName: DateTime.now(),
            });
          });

          testWidgets(
            ': List.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsOneWidget);
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

                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(insertedMemMemo), findsNothing);
                const enteringMemNameText =
                    '$scenarioName: Save: Create - mem name - entering';
                await widgetTester.enterText(
                  memNameTextFormFieldFinder,
                  enteringMemNameText,
                );
                await widgetTester.pumpAndSettle();

                expect(find.text(enteringMemNameText), findsOneWidget);
                const enteringMemMemoText =
                    '$scenarioName: Save: Create - mem memo - entering';
                await widgetTester.enterText(
                  memMemoTextFormFieldFinder,
                  enteringMemMemoText,
                );
                await widgetTester.pumpAndSettle();

                expect(find.text(enteringMemMemoText), findsOneWidget);
                await widgetTester.tap(saveMemFabFinder);
                await widgetTester.pumpAndSettle();

                const saveSuccessText = 'Save success. $enteringMemNameText';
                expect(
                  find.text(saveSuccessText),
                  findsOneWidget,
                );
                await widgetTester.pumpAndSettle(defaultDismissDuration);

                expect(find.text(saveSuccessText), findsNothing);
                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle();

                expect(find.text(insertedMemName), findsOneWidget);
                expect(find.text(enteringMemNameText), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsNothing);
                await widgetTester.tap(find.text(enteringMemNameText));
                await widgetTester.pumpAndSettle();

                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsOneWidget);
              },
            );

            testWidgets(
              ': Update.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                const enteringMemNameText =
                    '$scenarioName: Save: Update - mem name - entering';
                await widgetTester.enterText(
                  memNameTextFormFieldFinder,
                  enteringMemNameText,
                );
                await widgetTester.pumpAndSettle();

                expect(find.text(enteringMemNameText), findsOneWidget);
                await widgetTester.tap(find.text(insertedMemMemo));
                await widgetTester.pumpAndSettle();

                const enteringMemMemoText =
                    '$scenarioName: Save: Update - mem memo - entering';
                await widgetTester.enterText(
                  memMemoTextFormFieldFinder,
                  enteringMemMemoText,
                );
                await widgetTester.pumpAndSettle();

                expect(find.text(enteringMemMemoText), findsOneWidget);
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

                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
                await widgetTester.tap(find.text(enteringMemNameText));
                await widgetTester.pumpAndSettle();

                expect(find.text(insertedMemName), findsNothing);
                expect(find.text(enteringMemNameText), findsOneWidget);
                expect(find.text(enteringMemMemoText), findsOneWidget);
              },
            );

            group(': Archive', () {
              const unarchivedMemName =
                  '$scenarioName: V2: Archive: unarchived';
              const archivedMemName = 'Memo scenario: V2: Archive: archived';

              setUp(() async {
                final memTable = db.getTable(memTableDefinition.name);

                await memTable.insert({
                  defMemName.name: unarchivedMemName,
                  createdAtColumnName: DateTime.now(),
                });
                await memTable.insert({
                  defMemName.name: archivedMemName,
                  createdAtColumnName: DateTime.now(),
                  archivedAtColumnName: DateTime.now(),
                });
              });

              testWidgets(
                ': archive & unarchive.',
                (widgetTester) async {
                  await runApplication();
                  await widgetTester.pumpAndSettle();

                  expect(find.text(unarchivedMemName), findsOneWidget);
                  expect(find.text(archivedMemName), findsNothing);

                  await widgetTester.tap(find.text(insertedMemName));
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(find.byIcon(Icons.archive));
                  await widgetTester.pumpAndSettle();

                  expect(
                    find.text(insertedMemName),
                    findsNothing,
                  );
                  await widgetTester.tap(memListFilterButton);
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(findShowArchiveSwitch);
                  await widgetTester.pumpAndSettle();

                  await closeMemListFilter(widgetTester);
                  await widgetTester.pumpAndSettle();

                  expect(find.text(unarchivedMemName), findsOneWidget);
                  expect(find.text(archivedMemName), findsOneWidget);
                  await widgetTester.tap(find.text(insertedMemName));
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(find.byIcon(Icons.unarchive));
                  await widgetTester.pumpAndSettle();

                  await widgetTester.pageBack();
                  await widgetTester.pumpAndSettle();

                  expect(find.text(unarchivedMemName), findsOneWidget);
                  expect(find.text(archivedMemName), findsOneWidget);
                  await widgetTester.tap(memListFilterButton);
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(findShowNotArchiveSwitch);
                  await widgetTester.pumpAndSettle();

                  await closeMemListFilter(widgetTester);
                  await widgetTester.pumpAndSettle();

                  expect(find.text(insertedMemName), findsNothing);
                  expect(find.text(unarchivedMemName), findsNothing);
                  expect(find.text(archivedMemName), findsOneWidget);
                },
              );
            });
          });

          testWidgets(
            ': Remove & undo.',
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.more_vert));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.delete));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text('OK'));
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsNothing);

              await widgetTester.tap(find.byIcon(Icons.filter_list));
              await widgetTester.pumpAndSettle(defaultDuration);

              await widgetTester.tap(find.byType(Switch).at(1));
              await widgetTester.tap(find.byType(Switch).at(3));
              await widgetTester.pumpAndSettle(defaultDuration);

              await closeMemListFilter(widgetTester);
              await widgetTester.pumpAndSettle(defaultDuration);

              expect(find.text(insertedMemName), findsNothing);
              await widgetTester.tap(find.text('Undo'));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle();

              expect(find.text(insertedMemName), findsOneWidget);
              expect(find.text(insertedMemMemo), findsOneWidget);
            },
          );
        });

        group(': V1', () {
          setUpAll(() async {
            await DatabaseManager(onTest: true).open(databaseDefinition);
          });
          setUp(() async {
            await clearDatabase();
          });
          tearDownAll(() async {
            await DatabaseManager().delete(databaseDefinition.name);
          });

          testWidgets(
            'MemItem is nothing',
            (widgetTester) async {
              const savedMemName = '$scenarioName: saved mem name';
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
        });
      },
    );
