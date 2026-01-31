import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mem/features/mems/detail/page.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mems/detail/app_bar/remove_mem_action.dart';

import 'mem_detail_page_test.mocks.dart';

class _TestConstants {
  static const int testMemId = 1;
}

Widget _createTestWidget({
  int? memId,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: MemDetailPage(memId),
    ),
  );
}

Future<void> _pumpAndSettle(
  WidgetTester tester, {
  int? memId,
}) async {
  await tester.pumpWidget(_createTestWidget(memId: memId));

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));

  try {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  } catch (e) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

// FIXME 手間が多すぎる
//   MemStoreに統合することで解消する
//   そもそもRepositoryは集約するべきなのに、テーブルごとに実装したのが誤り
@GenerateMocks([
  MemClient,
  MemRepository,
  MemNotificationRepository,
  TargetRepository,
  MemItemRepository,
  MemRelationRepository,
])
void main() {
  final mockMemClient = MockMemClient();
  final mockMemRepository = MockMemRepository();
  final mockMemNotificationRepository = MockMemNotificationRepository();
  final mockMemItemRepository = MockMemItemRepository();
  final mockMemRelationRepository = MockMemRelationRepository();
  final mockTargetRepository = MockTargetRepository();

  MemClient(mock: mockMemClient);
  MemRepository(mock: mockMemRepository);
  MemNotificationRepository(mock: mockMemNotificationRepository);
  MemItemRepository(mock: mockMemItemRepository);
  MemRelationRepository(mock: mockMemRelationRepository);
  TargetRepository(mock: mockTargetRepository);

  setUp(() {
    when(mockMemRepository.ship(
      id: anyNamed('id'),
      archived: anyNamed('archived'),
      done: anyNamed('done'),
      condition: anyNamed('condition'),
      groupBy: anyNamed('groupBy'),
      orderBy: anyNamed('orderBy'),
      offset: anyNamed('offset'),
      limit: anyNamed('limit'),
    )).thenAnswer((_) async => []);
  });

  tearDown(() {
    reset(mockMemClient);
    reset(mockMemRepository);
    reset(mockMemNotificationRepository);
    reset(mockMemItemRepository);
    reset(mockMemRelationRepository);
    reset(mockTargetRepository);
  });

  group('MemDetailPage test', () {
    group('should display', () {
      testWidgets('basic structure for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
        expect(appBar.backgroundColor, isNull);
      });

      testWidgets('no app bar actions for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
      });
    });

    group('should show', skip: true, () {
      setUp(() {
        when(mockMemRepository.ship(id: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemEntityV1(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defColMemsName.name: 'Test Mem',
                      defColMemsDoneAt.name: null,
                      defColMemsStartOn.name: null,
                      defColMemsEndOn.name: null,
                      defColMemsStartAt.name: null,
                      defColMemsEndAt.name: null,
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);
        when(mockMemNotificationRepository.ship(
                memId: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemNotificationEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkMemNotificationsMemId.name: _TestConstants.testMemId,
                      defColMemNotificationsType.name:
                          MemNotificationType.repeat.name,
                      defColMemNotificationsTime.name: 10,
                      defColMemNotificationsMessage.name: 'Test Mem',
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockMemItemRepository.ship(memId: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemItemEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkMemItemsMemId.name: _TestConstants.testMemId,
                      defColMemItemsType.name: MemItemType.memo.name,
                      defColMemItemsValue.name: 'Test Mem',
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockTargetRepository.ship(
                condition: Equals(defFkTargetMemId, _TestConstants.testMemId)))
            .thenAnswer((_) async => [
                  SavedTargetEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkTargetMemId.name: _TestConstants.testMemId,
                      defColTargetType.name: TargetType.equalTo.name,
                      defColTargetUnit.name: TargetUnit.count.name,
                      defColTargetValue.name: 10,
                      defColTargetPeriod.name: Period.aDay.name,
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockMemRelationRepository.ship(
          sourceMemId: _TestConstants.testMemId,
        )).thenAnswer((_) async => [
              SavedMemRelationEntity(
                {
                  defPkId.name: _TestConstants.testMemId,
                  defFkMemRelationsSourceMemId.name: _TestConstants.testMemId,
                  defFkMemRelationsTargetMemId.name: _TestConstants.testMemId,
                  defColMemRelationsType.name: MemRelationType.prePost.name,
                  defColMemRelationsValue.name: 10,
                  defColCreatedAt.name: DateTime.now(),
                  defColUpdatedAt.name: null,
                  defColArchivedAt.name: null,
                },
              ),
            ]);
      });

      testWidgets('basic structure for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.backgroundColor, isNull);
      });

      testWidgets('app bar actions for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        await tester.pump(const Duration(milliseconds: 200));

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.length, greaterThan(0));
      });
    });

    group('should save', () {
      testWidgets('mem when save FAB is tapped with valid input.',
          (tester) async {
        const testMemName = 'Test Mem';

        when(mockMemClient.save(
          any,
          any,
          any,
          any,
          any,
        )).thenAnswer((_) async => (
              (
                MemEntityV1(Mem(1, "", null, null)),
                <MemItemEntity>[],
                null,
                null,
                null
              ),
              null,
            ));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: const MemDetailPage(null),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nameField = find.byKey(keyMemName);
        expect(nameField, findsOneWidget);

        await tester.enterText(nameField, testMemName);
        await tester.pumpAndSettle();

        final saveFab = find.byKey(keySaveMemFab);
        expect(saveFab, findsOneWidget);

        await tester.tap(saveFab);
        await tester.pumpAndSettle();

        verify(mockMemClient.save(
          any,
          any,
          any,
          any,
          any,
        )).called(1);
        expect(find.byType(SnackBar), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final expectedMessage = buildL10n().saveMemSuccessMessage(testMemName);
        expect(snackBar.content, isA<Text>());
        expect((snackBar.content as Text).data, equals(expectedMessage));
      });
    });

    group('should delete', skip: true, () {
      setUp(() {
        when(mockMemRepository.ship(id: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemEntityV1(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defColMemsName.name: 'Test Mem',
                      defColMemsDoneAt.name: null,
                      defColMemsStartOn.name: null,
                      defColMemsEndOn.name: null,
                      defColMemsStartAt.name: null,
                      defColMemsEndAt.name: null,
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);
        when(mockMemNotificationRepository.ship(
                memId: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemNotificationEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkMemNotificationsMemId.name: _TestConstants.testMemId,
                      defColMemNotificationsType.name:
                          MemNotificationType.repeat.name,
                      defColMemNotificationsTime.name: 10,
                      defColMemNotificationsMessage.name: 'Test Mem',
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockMemItemRepository.ship(memId: _TestConstants.testMemId))
            .thenAnswer((_) async => [
                  SavedMemItemEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkMemItemsMemId.name: _TestConstants.testMemId,
                      defColMemItemsType.name: MemItemType.memo.name,
                      defColMemItemsValue.name: 'Test Mem',
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockTargetRepository.ship(
                condition: Equals(defFkTargetMemId, _TestConstants.testMemId)))
            .thenAnswer((_) async => [
                  SavedTargetEntity(
                    {
                      defPkId.name: _TestConstants.testMemId,
                      defFkTargetMemId.name: _TestConstants.testMemId,
                      defColTargetType.name: TargetType.equalTo.name,
                      defColTargetUnit.name: TargetUnit.count.name,
                      defColTargetValue.name: 10,
                      defColTargetPeriod.name: Period.aDay.name,
                      defColCreatedAt.name: DateTime.now(),
                      defColUpdatedAt.name: null,
                      defColArchivedAt.name: null,
                    },
                  ),
                ]);

        when(mockMemRelationRepository.ship(
          sourceMemId: _TestConstants.testMemId,
        )).thenAnswer((_) async => [
              SavedMemRelationEntity(
                {
                  defPkId.name: _TestConstants.testMemId,
                  defFkMemRelationsSourceMemId.name: _TestConstants.testMemId,
                  defFkMemRelationsTargetMemId.name: _TestConstants.testMemId,
                  defColMemRelationsType.name: MemRelationType.prePost.name,
                  defColMemRelationsValue.name: 10,
                  defColCreatedAt.name: DateTime.now(),
                  defColUpdatedAt.name: null,
                  defColArchivedAt.name: null,
                },
              ),
            ]);
      });

      testWidgets('mem when delete action is tapped.', (tester) async {
        when(mockMemClient.remove(_TestConstants.testMemId))
            .thenAnswer((_) async => true);

        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);
        await tester.pump(const Duration(milliseconds: 200));

        // AppBarのアクションが表示されることを確認
        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.length, greaterThan(0));

        // 削除アクションを直接探す（PopupMenuButtonの中にある場合）
        final removeAction = find.byKey(keyRemoveMem);
        if (removeAction.evaluate().isEmpty) {
          // PopupMenuButtonを探してタップ
          final menuButton = find.byType(PopupMenuButton);
          if (menuButton.evaluate().isNotEmpty) {
            await tester.tap(menuButton);
            await tester.pump(const Duration(milliseconds: 200));
          }
        }

        // 削除アクションをタップ
        expect(removeAction, findsOneWidget);

        // ListTileのonTapを直接呼び出す
        final listTile = tester.widget<ListTile>(removeAction);
        if (listTile.onTap != null) {
          listTile.onTap!();
          await tester.pump(const Duration(milliseconds: 200));
        } else {
          await tester.tap(removeAction, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 200));
        }

        // 確認ダイアログが表示されることを確認
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Can I remove this?'), findsOneWidget);

        // OKボタンをタップして削除を実行
        final okButton = find.byKey(keyOk);
        expect(okButton, findsOneWidget);
        await tester.tap(okButton);
        await tester.pump(const Duration(milliseconds: 200));

        verify(mockMemClient.remove(_TestConstants.testMemId)).called(1);
      });
    });
  });
}
