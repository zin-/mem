import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';

import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';

void main() {
  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  testWidgets('Show saved mem list', (widgetTester) async {
    final mems = List.generate(
      5,
      (index) => Mem(
        id: index,
        name: 'Test $index',
        createdAt: DateTime.now(),
      ),
    );

    when(mockedMemRepository.ship(any)).thenAnswer(
      (realInvocation) async => mems,
    );

    await widgetTester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          title: 'test',
          home: MemListPage(),
        ),
      ),
    );
    await widgetTester.pumpAndSettle();

    for (var mem in mems) {
      expectMemNameTextOnListAt(widgetTester, mem.id, mem.name);
    }
    await widgetTester.tap(memListTileFinder.at(0));
    await widgetTester.pump();

    verify(mockedMemRepository.ship(false)).called(1);
    verifyNever(mockedMemRepository.shipWhereIdIs(any));
  });

  group('Transit', () {
    testWidgets(': new MemDetailPage', (widgetTester) async {
      when(mockedMemRepository.ship(any)).thenAnswer(
        (realInvocation) async => [],
      );

      await widgetTester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemListPage(),
          ),
        ),
      );
      await widgetTester.pump();

      expect(showNewMemFabFinder, findsOneWidget);
      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, '');

      verify(mockedMemRepository.ship(false)).called(1);
      verifyNever(mockedMemRepository.shipWhereIdIs(any));
    });

    testWidgets(': saved MemDetailPage', (widgetTester) async {
      final savedMem1 =
          Mem(id: 1, name: 'mem detail', createdAt: DateTime.now());
      final savedMem2 = Mem(id: 2, name: 'mem list', createdAt: DateTime.now());
      when(mockedMemRepository.ship(any)).thenAnswer(
        (realInvocation) async => [savedMem1, savedMem2],
      );

      await widgetTester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemListPage(),
          ),
        ),
      );
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, savedMem1.name);
      expect(
        (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField)
            .initialValue,
        isNot(savedMem2.name),
      );

      verify(mockedMemRepository.ship(false)).called(1);
      verifyNever(mockedMemRepository.shipWhereIdIs(any));
    });
  });

  group('Filter', () {
    testWidgets(': default.', (widgetTester) async {
      final notArchived = Mem(
        id: 1,
        name: 'not archived',
        createdAt: DateTime.now(),
        archivedAt: null,
      );
      final archived = Mem(
        id: 1,
        name: 'archived',
        createdAt: DateTime.now(),
        archivedAt: DateTime.now(),
      );
      when(mockedMemRepository.ship(any)).thenAnswer(
        (realInvocation) async => [notArchived],
      );

      await widgetTester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemListPage(),
          ),
        ),
      );
      await widgetTester.pumpAndSettle();

      expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
      expect(find.text(archived.name), findsNothing);

      await widgetTester.tap(find.byIcon(Icons.filter_list));
      await widgetTester.pump();

      expect(
        (widgetTester.widget(findShowNotArchiveSwitch) as Switch).value,
        true,
      );
      expect(
        (widgetTester.widget(findShowArchiveSwitch) as Switch).value,
        false,
      );

      verify(mockedMemRepository.ship(false)).called(1);
    });

    testWidgets(': change.', (widgetTester) async {
      final notArchived = Mem(
        id: 1,
        name: 'not archived',
        createdAt: DateTime.now(),
        archivedAt: null,
      );
      final archived = Mem(
        id: 2,
        name: 'archived',
        createdAt: DateTime.now(),
        archivedAt: DateTime.now(),
      );
      final notArchived2 = Mem(
        id: 3,
        name: 'not archived 2',
        createdAt: DateTime.now(),
        archivedAt: null,
      );
      final archived2 = Mem(
        id: 4,
        name: 'archived 2',
        createdAt: DateTime.now(),
        archivedAt: DateTime.now().add(const Duration(microseconds: 1)),
      );
      final returns = <List<Mem>>[
        [notArchived2, notArchived],
        [],
        [archived2, archived],
        [notArchived2, archived2, notArchived, archived],
      ];
      when(mockedMemRepository.ship(any)).thenAnswer(
        (realInvocation) async => returns.removeAt(0),
      );

      await widgetTester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemListPage(),
          ),
        ),
      );
      await widgetTester.pumpAndSettle();

      // showNotArchived: true, showArchived: false
      expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
      expect(find.text(archived.name), findsNothing);

      await widgetTester.tap(find.byIcon(Icons.filter_list));
      await widgetTester.pumpAndSettle();

      // showNotArchived: false, showArchived: false
      await widgetTester.tap(findShowNotArchiveSwitch);
      await widgetTester.pumpAndSettle();

      expect(find.text(notArchived.name), findsNothing);
      expect(find.text(archived.name), findsNothing);

      // showNotArchived: false, showArchived: true
      await widgetTester.tap(findShowArchiveSwitch);
      await widgetTester.pumpAndSettle();

      expect(find.text(notArchived.name), findsNothing);
      expectMemNameTextOnListAt(widgetTester, 0, archived.name);

      // showNotArchived: true, showArchived: true
      await widgetTester.tap(findShowNotArchiveSwitch);
      await widgetTester.pumpAndSettle();

      expectMemNameTextOnListAt(widgetTester, 0, notArchived.name);
      expectMemNameTextOnListAt(widgetTester, 1, notArchived2.name);
      expectMemNameTextOnListAt(widgetTester, 2, archived.name);
      expectMemNameTextOnListAt(widgetTester, 3, archived2.name);

      verify(mockedMemRepository.ship(any)).called(4);
    });
  });
}

final memListTileFinder = find.byType(ListTile);
final showNewMemFabFinder = find.byType(FloatingActionButton);

Finder findMemNameTextOnListAt(int index) => find.descendant(
      of: memListTileFinder.at(index),
      matching: find.byType(Text),
    );

Text getMemNameTextOnListAt(WidgetTester widgetTester, int index) =>
    widgetTester.widget(findMemNameTextOnListAt(index)) as Text;

void expectMemNameTextOnListAt(
  WidgetTester widgetTester,
  int index,
  String memName,
) =>
    expect(
      getMemNameTextOnListAt(widgetTester, index).data,
      memName,
    );

final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);
