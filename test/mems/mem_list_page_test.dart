import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/mems/mem_list_page.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
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
  MemRepository.reset(mockedMemRepository);
  MemItemRepository.reset(MockMemItemRepository());

  tearDown(() {
    reset(mockedMemRepository);
  });

  testWidgets(
    'Show saved mem list',
    (widgetTester) async {
      final mems = List.generate(
        5,
        (index) => MemEntity(
          id: index,
          name: 'Test $index',
          createdAt: DateTime.now(),
        ),
      );

      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer(
        (realInvocation) => Future.value(mems),
      );

      await pumpMemListPage(widgetTester);

      verify(mockedMemRepository.ship(
        whereMap: null,
        archive: false,
        done: false,
      )).called(1);

      await widgetTester.pumpAndSettle();

      mems.asMap().forEach((index, mem) {
        expectMemNameTextOnListAt(widgetTester, index, mem.name);
      });

      verifyNever(mockedMemRepository.shipById(any));
    },
    tags: TestSize.small,
  );

  group('Filter', () {
    testWidgets(
      ': default',
      (widgetTester) async {
        final notArchived = minSavedMemEntity(1)
          ..name = 'not archived'
          ..archivedAt = null;
        final archived = minSavedMemEntity(2)
          ..name = 'archived'
          ..archivedAt = DateTime.now();
        final notDone = minSavedMemEntity(3)
          ..name = 'not done'
          ..doneAt = null;
        final done = minSavedMemEntity(4)
          ..name = 'done'
          ..doneAt = DateTime.now();

        when(mockedMemRepository.ship(
          whereMap: anyNamed('whereMap'),
          archive: anyNamed('archive'),
          done: anyNamed('done'),
        )).thenAnswer(
          (realInvocation) => Future.value([notArchived, notDone]),
        );

        await pumpMemListPage(widgetTester);
        await widgetTester.pumpAndSettle();
        verify(mockedMemRepository.ship(
          whereMap: null,
          archive: false,
          done: false,
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
      tags: TestSize.small,
    );

    group(': onChanged', () {
      testWidgets(
        ': archive',
        (widgetTester) async {
          final notArchived = minSavedMemEntity(1)
            ..archivedAt = null
            ..name = 'not archived';
          final archived = minSavedMemEntity(2)
            ..archivedAt = DateTime.now()
            ..name = 'archived';
          final notArchived2 = minSavedMemEntity(3)
            ..archivedAt = null
            ..name = 'not archived 2';
          final archived2 = minSavedMemEntity(4)
            ..archivedAt = DateTime.now().add(const Duration(microseconds: 1))
            ..name = 'archived 2';
          final returns = <List<MemEntity>>[
            [notArchived2],
            [archived2],
            [archived2, archived],
            [notArchived2, archived2, notArchived, archived],
          ];

          when(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: anyNamed('done'),
          )).thenAnswer(
            (realInvocation) => Future.value(returns.removeAt(0)),
          );

          await pumpMemListPage(widgetTester);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: null,
            archive: false,
            done: false,
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
          verify(mockedMemRepository.ship(
            whereMap: null,
            archive: null,
            done: false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, notArchived2.name);
          expectMemNameTextOnListAt(widgetTester, 1, archived2.name);
          expect(find.text(notArchived.name), findsNothing);
          expect(find.text(archived.name), findsNothing);

          // showNotArchived: false, showArchived: true
          await widgetTester.tap(findShowArchiveSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: null,
            archive: true,
            done: false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, archived.name);
          expectMemNameTextOnListAt(widgetTester, 1, archived2.name);
          expect(find.text(notArchived.name), findsNothing);
          expect(find.text(notArchived2.name), findsNothing);

          // showNotArchived: true, showArchived: true
          await widgetTester.tap(findShowNotArchiveSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: null,
            archive: null,
            done: false,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 4);
          expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
          expectMemNameTextOnListAt(widgetTester, 1, notArchived2.name);
          expectMemNameTextOnListAt(widgetTester, 2, archived.name);
          expectMemNameTextOnListAt(widgetTester, 3, archived2.name);
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': done',
        (widgetTester) async {
          final notDone = minSavedMemEntity(1)
            ..doneAt = null
            ..name = 'not done';
          final done = minSavedMemEntity(2)
            ..doneAt = DateTime.now()
            ..name = 'done';
          final notDone2 = minSavedMemEntity(3)
            ..doneAt = null
            ..name = 'not done 2';
          final done2 = minSavedMemEntity(4)
            ..doneAt = DateTime.now().add(const Duration(microseconds: 1))
            ..name = 'done 2';
          final returns = <List<MemEntity>>[
            [notDone2],
            [done2],
            [done2, done],
            [notDone2, done2, notDone, done],
          ];
          when(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: anyNamed('done'),
          )).thenAnswer(
            (realInvocation) => Future.value(returns.removeAt(0)),
          );

          await pumpMemListPage(widgetTester);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: false,
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
          verify(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: null,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, notDone2.name);
          expectMemNameTextOnListAt(widgetTester, 1, done2.name);
          expect(find.text(notDone.name), findsNothing);
          expect(find.text(done.name), findsNothing);

          // showNotDone: false, showDone: true
          await widgetTester.tap(findShowDoneSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: true,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 2);
          expectMemNameTextOnListAt(widgetTester, 0, done.name);
          expectMemNameTextOnListAt(widgetTester, 1, done2.name);
          expect(find.text(notDone.name), findsNothing);
          expect(find.text(notDone2.name), findsNothing);

          // showNotDone: true, showDone: true
          await widgetTester.tap(findShowNotDoneSwitch);
          await widgetTester.pumpAndSettle();
          verify(mockedMemRepository.ship(
            whereMap: anyNamed('whereMap'),
            archive: anyNamed('archive'),
            done: null,
          )).called(1);

          expect(widgetTester.widgetList(memListTileFinder).length, 4);
          expectMemNameTextOnListAt(widgetTester, 0, notDone.name);
          expectMemNameTextOnListAt(widgetTester, 1, notDone2.name);
          expectMemNameTextOnListAt(widgetTester, 2, done.name);
          expectMemNameTextOnListAt(widgetTester, 3, done2.name);
        },
        tags: TestSize.small,
      );
    });
  });

  group('Sort', () {
    testWidgets(
      ': notifyOn',
      (widgetTester) async {
        final now = DateTime.now();
        final nowDate = DateTime(now.year, now.month, now.day);

        final notifyOnIsNull = minSavedMemEntity(1)
          ..name = 'notifyOn is null'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = null;
        final notifyOnNow = minSavedMemEntity(2)
          ..name = 'notifyOn is now'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate;
        final notifyOnOneDayAgo = minSavedMemEntity(3)
          ..name = 'notifyOn is one day ago'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate.add(const Duration(days: -1));
        final notifyOnOneDayLater = minSavedMemEntity(4)
          ..name = 'notifyOn is one day later'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate.add(const Duration(days: 1));
        final notifyOnNow2 = minSavedMemEntity(5)
          ..name = 'notifyOn is now 2'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = DateTime(now.year, now.month, now.day);
        final notifyOnOneDayAgo2 = minSavedMemEntity(6)
          ..name = 'notifyOn is one day ago 2'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate.add(const Duration(days: -1));
        final notifyOnOneDayLater2 = minSavedMemEntity(7)
          ..name = 'notifyOn is one day later 2'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate.add(const Duration(days: 1));

        when(mockedMemRepository.ship(
                whereMap: anyNamed('whereMap'),
                archive: anyNamed('archive'),
                done: anyNamed('done')))
            .thenAnswer((realInvocation) => Future.value([
                  notifyOnNow,
                  notifyOnIsNull,
                  notifyOnOneDayAgo,
                  notifyOnOneDayLater,
                  notifyOnNow2,
                  notifyOnOneDayAgo2,
                  notifyOnOneDayLater2,
                ]));

        await pumpMemListPage(widgetTester);
        await widgetTester.pumpAndSettle();

        expectMemNameTextOnListAt(widgetTester, 0, notifyOnOneDayAgo.name);
        expectMemNameTextOnListAt(widgetTester, 1, notifyOnOneDayAgo2.name);
        expectMemNameTextOnListAt(widgetTester, 2, notifyOnNow.name);
        expectMemNameTextOnListAt(widgetTester, 3, notifyOnNow2.name);
        expectMemNameTextOnListAt(widgetTester, 4, notifyOnOneDayLater.name);
        expectMemNameTextOnListAt(widgetTester, 5, notifyOnOneDayLater2.name);
        expectMemNameTextOnListAt(widgetTester, 6, notifyOnIsNull.name);
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': notifyAt',
      (widgetTester) async {
        final now = DateTime.now();
        final nowDate = DateTime(now.year, now.month, now.day);
        final nowDateTime =
            DateTime(now.year, now.month, now.day, now.hour, now.minute);

        final notifyOnIsNull = minSavedMemEntity(1)
          ..name = 'notifyOn is null'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = null
          ..notifyAt = null;
        final notifyAtIsNull = minSavedMemEntity(2)
          ..name = 'notifyAt is null'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate
          ..notifyAt = null;
        final notifyAtNow = minSavedMemEntity(3)
          ..name = 'notifyAt is now'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate
          ..notifyAt = nowDateTime;
        final notifyAtOneHourAgo = minSavedMemEntity(4)
          ..name = 'notifyAt is one hour ago'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate
          ..notifyAt = nowDateTime.add(const Duration(hours: -1));
        final notifyAtOneMinuteLater = minSavedMemEntity(5)
          ..name = 'notifyAt is one minute later'
          ..doneAt = null
          ..archivedAt = null
          ..notifyOn = nowDate
          ..notifyAt = nowDateTime.add(const Duration(minutes: 1));

        when(mockedMemRepository.ship(
                whereMap: anyNamed('whereMap'),
                archive: anyNamed('archive'),
                done: anyNamed('done')))
            .thenAnswer((realInvocation) => Future.value([
                  notifyOnIsNull,
                  notifyAtIsNull,
                  notifyAtNow,
                  notifyAtOneHourAgo,
                  notifyAtOneMinuteLater,
                ]));

        await pumpMemListPage(widgetTester);
        await widgetTester.pumpAndSettle();

        expectMemNameTextOnListAt(widgetTester, 0, notifyAtIsNull.name);
        expectMemNameTextOnListAt(widgetTester, 1, notifyAtOneHourAgo.name);
        expectMemNameTextOnListAt(widgetTester, 2, notifyAtNow.name);
        expectMemNameTextOnListAt(widgetTester, 3, notifyAtOneMinuteLater.name);
        expectMemNameTextOnListAt(widgetTester, 4, notifyOnIsNull.name);
      },
      tags: TestSize.small,
    );
  });

  testWidgets(
    'Hide fab on scroll.',
    (widgetTester) async {
      final mems = List.generate(
        20,
        (index) => MemEntity(
          id: index,
          name: 'Test $index',
          createdAt: DateTime.now(),
        ),
      );

      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer(
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
    tags: TestSize.small,
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
