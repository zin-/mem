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

  testWidgets('new', (widgetTester) async {
    final mems = List.generate(
      10,
      (index) => Mem(
        id: index,
        name: 'Test $index',
        createdAt: DateTime.now(),
      ),
    );

    when(mockedMemRepository.shipAll()).thenAnswer(
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
    await widgetTester.pump();

    mems.asMap().forEach((index, mem) {
      final listTile = find.byType(ListTile).at(index);
      final memListTileNameText = widgetTester.widget(
          find.descendant(of: listTile, matching: find.byType(Text))) as Text;
      expect(memListTileNameText.data, mem.name);
    });
  });
}
