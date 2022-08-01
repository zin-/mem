import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/mem.dart';
import 'package:mockito/mockito.dart';

import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_list/mem_list_page.dart';

import '../mocks.mocks.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  testWidgets('Show saved mem list', (widgetTester) async {
    final mems = List.generate(
      10,
      (index) => Mem(
        id: index,
        name: 'Test $index',
        createdAt: DateTime.now(),
      ),
    );

    when(mockedMemRepository.ship(any)).thenAnswer(
      (realInvocation) async => mems,
    );
    when(mockedMemRepository.shipWhereIdIs(0)).thenAnswer(
      (realInvocation) async => mems[0],
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

    mems.asMap().forEach((index, mem) {
      expectMemNameTextOnListAt(widgetTester, index, mem.name);
    });
    await widgetTester.tap(memListTileFinder.at(0));
    await widgetTester.pump();

    verify(mockedMemRepository.ship(false)).called(1);
    verify(mockedMemRepository.shipWhereIdIs(0)).called(1);
  });

  testWidgets('Transit new MemDetailPage', (widgetTester) async {
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
    await widgetTester.pump();

    verify(mockedMemRepository.ship(false)).called(1);
    verify(mockedMemRepository.shipWhereIdIs(0)).called(1);
  });
}

final memListTileFinder = find.byType(ListTile);
final showNewMemFabFinder = find.byType(FloatingActionButton);

Finder findMemNameTextOnListAt(int index) => find.descendant(
    of: memListTileFinder.at(index), matching: find.byType(Text));

Text getMemNameTextOnListAt(WidgetTester widgetTester, int index) =>
    widgetTester.widget(findMemNameTextOnListAt(index)) as Text;

void expectMemNameTextOnListAt(
  WidgetTester widgetTester,
  int index,
  String memName,
) =>
    expect(
      getMemNameTextOnListAt(widgetTester, 0).data,
      memName,
    );
