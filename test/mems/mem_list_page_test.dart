import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/mem_list_page.dart';
import 'package:mockito/mockito.dart';

import '../samples.dart';
import '../mocks.mocks.dart';

Future pumpMemListPage(WidgetTester widgetTester) async {
  await widgetTester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MemListPage(),
      ),
    ),
  );
}

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.resetWith(mockedMemItemRepository);

  tearDown(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
  });

  testWidgets(
    'Show saved mem list',
    (widgetTester) async {
      final mems = List.generate(
        5,
        (index) => minSavedMem(index)
          ..name = 'Test $index'
          ..createdAt = DateTime.now(),
      );

      // when(mockedMemRepository.ship(
      //   whereMap: anyNamed('whereMap'),
      //   archive: anyNamed('archive'),
      //   done: anyNamed('done'),
      // )).thenAnswer(
      //   (realInvocation) => Future.value(memEntities),
      // );
      when(mockedMemRepository.shipByCondition(any, any)).thenAnswer(
        (realInvocation) => Future.value(mems),
      );

      await pumpMemListPage(widgetTester);

      // verify(mockedMemRepository.ship(
      //   whereMap: null,
      //   archive: false,
      //   done: false,
      // )).called(1);
      expect(
        verify(mockedMemRepository.shipByCondition(
          captureAny,
          captureAny,
        )).captured,
        [false, false],
      );

      await widgetTester.pumpAndSettle();

      mems.asMap().forEach((index, mem) {
        expectMemNameTextOnListAt(widgetTester, index, mem.name);
      });
    },
  );

  group('Filter', () {
    testWidgets(
      ': default',
      (widgetTester) async {
        final notArchived = minSavedMem(1)
          ..name = 'not archived'
          ..archivedAt = null;
        final archived = minSavedMem(2)
          ..name = 'archived'
          ..archivedAt = DateTime.now();
        final notDone = minSavedMem(3)
          ..name = 'not done'
          ..doneAt = null;
        final done = minSavedMem(4)
          ..name = 'done'
          ..doneAt = DateTime.now();

        when(mockedMemRepository.shipByCondition(any, any)).thenAnswer(
          (realInvocation) => Future.value([notArchived, notDone]),
        );

        await pumpMemListPage(widgetTester);
        await widgetTester.pumpAndSettle();
        verify(mockedMemRepository.shipByCondition(
          false,
          false,
        )).called(1);

        expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
        expect(find.text(archived.name), findsNothing);
        expectMemNameTextOnListAt(widgetTester, 1, notDone.name);
        expect(find.text(done.name), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pump();

        expect(
          (widgetTester.widget(findShowNotArchiveSwitch) as Switch).value,
          true,
        );
        expect(
          (widgetTester.widget(findShowArchiveSwitch) as Switch).value,
          false,
        );
      },
    );

    group(': onChanged', () {
      testWidgets(
        ': archive',
        (widgetTester) async {
          final notArchived = minSavedMem(1)
            ..archivedAt = null
            ..name = 'not archived';
          final archived = minSavedMem(2)
            ..archivedAt = DateTime.now()
            ..name = 'archived';
          final notArchived2 = minSavedMem(3)
            ..archivedAt = null
            ..name = 'not archived 2';
          final archived2 = minSavedMem(4)
            ..archivedAt = DateTime.now().add(const Duration(microseconds: 1))
            ..name = 'archived 2';
          final returns = [
            [notArchived2],
            [archived2],
            [archived2, archived],
            [notArchived2, archived2, notArchived, archived],
          ];

          when(mockedMemRepository.shipByCondition(any, any)).thenAnswer(
            (realInvocation) => Future.value(returns.removeAt(0)),
          );

          await pumpMemListPage(widgetTester);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            false,
            false,
          )).called(1);

          // showNotArchived: true, showArchived: false
          expect(widgetTester.widgetList(memListTileFinder).length, 1);
          expectMemNameTextOnListAt(widgetTester, 0, notArchived2.name);
          expect(find.text(notArchived.name), findsNothing);
          expect(find.text(archived.name), findsNothing);
          expect(find.text(archived2.name), findsNothing);

          // showNotArchived: false, showArchived: false
          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(findShowNotArchiveSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            null,
            false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, notArchived2.name);
          expectMemNameTextOnListAt(widgetTester, 1, archived2.name);
          expect(find.text(notArchived.name), findsNothing);
          expect(find.text(archived.name), findsNothing);

          // showNotArchived: false, showArchived: true
          await widgetTester.tap(findShowArchiveSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            true,
            false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, archived.name);
          expectMemNameTextOnListAt(widgetTester, 1, archived2.name);
          expect(find.text(notArchived.name), findsNothing);
          expect(find.text(notArchived2.name), findsNothing);

          // showNotArchived: true, showArchived: true
          await widgetTester.tap(findShowNotArchiveSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            null,
            false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 4);
          expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
          expectMemNameTextOnListAt(widgetTester, 1, notArchived2.name);
          expectMemNameTextOnListAt(widgetTester, 2, archived.name);
          expectMemNameTextOnListAt(widgetTester, 3, archived2.name);
        },
      );

      testWidgets(
        ': done',
        (widgetTester) async {
          final notDone = minSavedMem(1)
            ..doneAt = null
            ..name = 'not done';
          final done = minSavedMem(2)
            ..doneAt = DateTime.now()
            ..name = 'done';
          final notDone2 = minSavedMem(3)
            ..doneAt = null
            ..name = 'not done 2';
          final done2 = minSavedMem(4)
            ..doneAt = DateTime.now().add(const Duration(microseconds: 1))
            ..name = 'done 2';
          final returns = [
            [notDone2],
            [done2],
            [done2, done],
            [notDone2, done2, notDone, done],
          ];
          when(mockedMemRepository.shipByCondition(any, any)).thenAnswer(
            (realInvocation) => Future.value(returns.removeAt(0)),
          );

          await pumpMemListPage(widgetTester);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            false,
            false,
          )).called(1);

          // showNotDone: true, showDone: false
          expect(widgetTester.widgetList(memListTileFinder).length, 1);
          expectMemNameTextOnListAt(widgetTester, 0, notDone2.name);
          expect(find.text(notDone.name), findsNothing);
          expect(find.text(done.name), findsNothing);
          expect(find.text(done2.name), findsNothing);

          // showNotDone: false, showDone: false
          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(findShowNotDoneSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            false,
            null,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, notDone2.name);
          expectMemNameTextOnListAt(widgetTester, 1, done2.name);
          expect(find.text(notDone.name), findsNothing);
          expect(find.text(done.name), findsNothing);

          // showNotDone: false, showDone: true
          await widgetTester.tap(findShowDoneSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            false,
            true,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, done.name);
          expectMemNameTextOnListAt(widgetTester, 1, done2.name);
          expect(find.text(notDone.name), findsNothing);
          expect(find.text(notDone2.name), findsNothing);

          // showNotDone: true, showDone: true
          await widgetTester.tap(findShowNotDoneSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.shipByCondition(
            false,
            null,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 4);
          expectMemNameTextOnListAt(widgetTester, 0, notDone.name);
          expectMemNameTextOnListAt(widgetTester, 1, notDone2.name);
          expectMemNameTextOnListAt(widgetTester, 2, done.name);
          expectMemNameTextOnListAt(widgetTester, 3, done2.name);
        },
      );
    });
  });

  testWidgets(
    'Hide fab on scroll.',
    (widgetTester) async {
      final mems = List.generate(
        20,
        (index) => minSavedMem(index)
          ..name = 'Test $index'
          ..createdAt = DateTime.now(),
      );

      when(mockedMemRepository.shipByCondition(any, any)).thenAnswer(
        (realInvocation) => Future.value(mems),
      );

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      await widgetTester.dragUntilVisible(
        find.text('Test 10'),
        memListFinder,
        const Offset(0, -500),
      );
      await widgetTester.pumpAndSettle();

      expect(showNewMemFabFinder.hitTestable(), findsNothing);

      await widgetTester.dragUntilVisible(
        find.text('Test 0'),
        memListFinder,
        const Offset(0, 500),
      );
      await widgetTester.pumpAndSettle();

      expect(showNewMemFabFinder.hitTestable(), findsOneWidget);
    },
  );
}

final memListFinder = find.byType(CustomScrollView);
final memListTileFinder = find.descendant(
  of: memListFinder,
  matching: find.byType(MemListItemView),
);
final showNewMemFabFinder = find.byType(FloatingActionButton);

Finder findMemNameTextOnListAt(int index) => find.descendant(
      of: find.descendant(
        of: memListTileFinder.at(index),
        matching: find.byType(MemNameText),
      ),
      matching: find.byType(Text),
    );

void expectMemNameTextOnListAt(
  WidgetTester widgetTester,
  int index,
  String memName,
) =>
    expect(
      widgetTester.widget<Text>(findMemNameTextOnListAt(index)).data,
      memName,
    );

final memListFilterButton = find.byIcon(Icons.filter_list);
final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);
final findShowNotDoneSwitch = find.byType(Switch).at(2);
final findShowDoneSwitch = find.byType(Switch).at(3);

Future closeMemListFilter(WidgetTester widgetTester) async {
  // FIXME なんか変な気がする
  await widgetTester.tapAt(const Offset(0, 0));
  await widgetTester.pumpAndSettle();
}
