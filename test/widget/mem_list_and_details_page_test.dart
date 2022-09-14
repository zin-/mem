import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';
import 'mem_list_page_test.dart';
import 'mem_detail_menu_test.dart';

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

  testWidgets(
    'Update mem',
    (widgetTester) async {
      final savedMemEntity = MemEntity(
        name: 'saved mem entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemRepository.ship(archived: false))
          .thenAnswer((realInvocation) => Future.value([savedMemEntity]));

      await pumpMemListPage(widgetTester);

      verify(mockedMemRepository.ship(archived: false)).called(1);

      final savedMemoMemItemEntity = MemItemEntity(
        memId: savedMemEntity.id,
        type: MemItemType.memo,
        value: 'saved memo mem item entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, savedMemEntity.name);
      expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);

      verifyNever(mockedMemRepository.shipById(any));
      verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).called(1);

      const enteringMemName = 'updating mem name';
      const enteringMemMemo = 'updating mem memo';

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);

      when(mockedMemRepository.update(any)).thenAnswer((realInvocation) {
        final memEntity = realInvocation.positionalArguments[0] as MemEntity;

        expect(memEntity.name, enteringMemName);
        expect(memEntity.id, savedMemEntity.id);
        expect(memEntity.createdAt, savedMemEntity.createdAt);
        expect(memEntity.updatedAt, null);
        expect(memEntity.archivedAt, null);

        return Future.value(MemEntity(
          name: memEntity.name,
          id: memEntity.id,
          createdAt: memEntity.createdAt,
          updatedAt: memEntity.updatedAt,
        ));
      });
      when(mockedMemItemRepository.update(any)).thenAnswer((realInvocation) {
        final memItemEntity =
            realInvocation.positionalArguments[0] as MemItemEntity;

        expect(memItemEntity.memId, savedMemoMemItemEntity.memId);
        expect(memItemEntity.type, savedMemoMemItemEntity.type);
        expect(memItemEntity.value, enteringMemMemo);
        expect(memItemEntity.id, savedMemoMemItemEntity.id);
        expect(memItemEntity.createdAt, savedMemoMemItemEntity.createdAt);
        expect(memItemEntity.updatedAt, null);
        expect(memItemEntity.archivedAt, null);

        return Future.value(MemItemEntity(
          memId: memItemEntity.memId,
          type: memItemEntity.type,
          value: memItemEntity.value,
          id: savedMemoMemItemEntity.id,
          createdAt: savedMemoMemItemEntity.createdAt,
          updatedAt: DateTime.now(),
        ));
      });

      await widgetTester.tap(saveFabFinder);

      verify(mockedMemRepository.update(any)).called(1);
      verify(mockedMemItemRepository.update(any)).called(1);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      verifyNever(mockedMemRepository.ship(
        archived: anyNamed('archived'),
        whereColumns: anyNamed('whereColumns'),
        whereArgs: anyNamed('whereArgs'),
      ));

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    },
  );

  testWidgets(
    'Archive mem',
    (widgetTester) async {
      final savedMemEntity = MemEntity(
        name: 'saved mem entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemRepository.ship(archived: false))
          .thenAnswer((realInvocation) => Future.value([savedMemEntity]));

      await pumpMemListPage(widgetTester);

      final savedMemoMemItemEntity = MemItemEntity(
        memId: savedMemEntity.id,
        type: MemItemType.memo,
        value: 'saved memo mem item entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      when(mockedMemRepository.archive(any)).thenAnswer((realInvocation) {
        final memEntity = realInvocation.positionalArguments[0] as MemEntity;

        expect(memEntity.toMap(), savedMemEntity.toMap());

        return Future.value(memEntity..archivedAt = DateTime.now());
      });
      when(mockedMemItemRepository.archiveByMemId(savedMemEntity.id))
          .thenAnswer((realInvocation) {
        final memId = realInvocation.positionalArguments[0] as int;

        expect(memId, savedMemEntity.id);

        return Future.value([savedMemoMemItemEntity]
            .map((e) => e..archivedAt = DateTime.now())
            .toList());
      });

      await widgetTester.tap(archiveButtonFinder);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepository.archive(any)).called(1);
      verify(mockedMemItemRepository.archiveByMemId(savedMemEntity.id))
          .called(1);

      expect(widgetTester.widgetList(memListTileFinder).length, 0);
    },
  );
}
