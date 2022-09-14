import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';
import 'mem_list_page_test.dart';

void main() {
  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.withMock(mockedMemItemRepository);

  tearDown(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
  });

  // TODO shorten
  testWidgets(
    'Create mem',
    (widgetTester) async {
      const enteringMemName = 'entering mem name';
      const enteringMemMemo = 'entering mem memo';

      when(mockedMemRepository.ship(archived: false))
          .thenAnswer((realInvocation) => Future.value([]));

      await pumpMemListPage(widgetTester);

      verify(mockedMemRepository.ship(archived: false)).called(1);

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, '');
      expectMemMemoOnMemDetail(widgetTester, '');

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);
      await widgetTester.pump();

      expectMemNameOnMemDetail(widgetTester, enteringMemName);
      expectMemMemoOnMemDetail(widgetTester, enteringMemMemo);

      const memId = 1;
      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) {
        final memEntity = realInvocation.positionalArguments[0] as MemEntity;

        expect(memEntity.name, enteringMemName);
        expect(memEntity.id, null);
        expect(memEntity.createdAt, null);
        expect(memEntity.updatedAt, null);
        expect(memEntity.archivedAt, null);

        return Future.value(MemEntity(
          name: memEntity.name,
          id: memId,
          createdAt: DateTime.now(),
        ));
      });
      const memItemId = 1;
      when(mockedMemItemRepository.receive(any)).thenAnswer((realInvocation) {
        final memItemEntity =
            realInvocation.positionalArguments[0] as MemItemEntity;

        expect(memItemEntity.memId, memId);
        expect(memItemEntity.type, MemItemType.memo);
        expect(memItemEntity.value, enteringMemMemo);
        expect(memItemEntity.id, null);
        expect(memItemEntity.createdAt, null);
        expect(memItemEntity.updatedAt, null);
        expect(memItemEntity.archivedAt, null);

        return Future.value(MemItemEntity(
          memId: memItemEntity.memId,
          type: memItemEntity.type,
          value: memItemEntity.value,
          id: memItemId,
          createdAt: DateTime.now(),
        ));
      });

      await widgetTester.tap(saveFabFinder);
      await widgetTester.pump();

      verify(mockedMemRepository.receive(any)).called(1);
      verify(mockedMemItemRepository.receive(any)).called(1);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, enteringMemName);
      expectMemMemoOnMemDetail(widgetTester, enteringMemMemo);

      verifyNever(mockedMemRepository.ship(
        archived: anyNamed('archived'),
        whereColumns: anyNamed('whereColumns'),
        whereArgs: anyNamed('whereArgs'),
      ));
      verifyNever(mockedMemItemRepository.shipByMemId(any));

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, '');
      expectMemMemoOnMemDetail(widgetTester, '');
    },
  );
}
