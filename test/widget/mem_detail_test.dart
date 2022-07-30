import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  group('new', () {
    testWidgets(': not found.', (widgetTester) async {
      when(mockedMemRepository.shipWhereIdIs(any))
          .thenThrow(NotFoundException('test target', 'test condition'));

      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemDetailPage(1),
          ),
        ),
      );
      await widgetTester.pump();

      expect(memNameFinder, findsOneWidget);
      expect(
        (widgetTester.widget(memNameFinder) as TextFormField).initialValue,
        '',
      );
      expect(saveFabFinder, findsOneWidget);

      verify(mockedMemRepository.shipWhereIdIs(1)).called(1);
    });
    testWidgets(': found.', (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      when(mockedMemRepository.shipWhereIdIs(any))
          .thenAnswer((realInvocation) async => Mem(
                id: memId,
                name: memName,
                createdAt: DateTime.now(),
              ));

      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemDetailPage(memId),
          ),
        ),
      );
      await widgetTester.pump();

      expect(memNameFinder, findsOneWidget);
      expect(
        (widgetTester.widget(memNameFinder) as TextFormField).initialValue,
        memName,
      );
      expect(saveFabFinder, findsOneWidget);

      verify(mockedMemRepository.shipWhereIdIs(memId)).called(1);
    });
  });

  group('save', () {
    testWidgets('create', (widgetTester) async {
      const enteringMemName = 'entering mem name';

      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0];
        expect(value['name'], enteringMemName);

        return Mem(id: 1, name: value['name'], createdAt: DateTime.now());
      });

      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemDetailPage(null),
          ),
        ),
      );
      await widgetTester.pump();

      await widgetTester.enterText(memNameFinder, enteringMemName);
      await widgetTester.tap(saveFabFinder);
      await widgetTester.pump();

      expect(find.text('Save success. $enteringMemName'), findsOneWidget);

      verifyNever(mockedMemRepository.shipWhereIdIs(null));
      verify(mockedMemRepository.receive(any)).called(1);
    });
    testWidgets('update', (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      const enteringMemName = 'entering mem name';

      when(mockedMemRepository.shipWhereIdIs(any))
          .thenAnswer((realInvocation) async => Mem(
                id: memId,
                name: memName,
                createdAt: DateTime.now(),
              ));
      when(mockedMemRepository.update(any)).thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0];
        expect(value.id, memId);
        expect(value.name, enteringMemName);

        return Mem(
          id: value.id,
          name: value.name,
          createdAt: value.createdAt,
          updatedAt: DateTime.now(),
        );
      });

      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemDetailPage(memId),
          ),
        ),
      );
      await widgetTester.pump();

      await widgetTester.enterText(memNameFinder, enteringMemName);
      await widgetTester.tap(saveFabFinder);
      await widgetTester.pump();

      expect(find.text('Save success. $enteringMemName'), findsOneWidget);

      verify(mockedMemRepository.shipWhereIdIs(memId)).called(1);
      verify(mockedMemRepository.update(any)).called(1);
    });
  });
}

final memNameFinder = find.byType(TextFormField).at(0);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);
