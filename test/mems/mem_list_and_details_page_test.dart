import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../samples.dart';
import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';
import 'mem_list_page_test.dart';
import 'mem_detail_menu_test.dart';
import 'mem_detail_body_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
  final mockedMemRepositoryV2 = MockMemRepositoryV2();
  MemRepositoryV2.resetWith(mockedMemRepositoryV2);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.reset(mockedMemItemRepository);

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

      when(mockedMemRepositoryV2.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepositoryV2.shipByCondition(false, false)).called(1);

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);
      await widgetTester.pump();

      const memId = 1;
      when(mockedMemRepositoryV2.receive(any)).thenAnswer((realInvocation) {
        final mem = realInvocation.positionalArguments[0] as Mem;

        expect(mem.name, enteringMemName);
        expect(mem.id, null);
        expect(mem.createdAt, null);
        expect(mem.updatedAt, null);
        expect(mem.archivedAt, null);

        return Future.value(Mem(
          name: mem.name,
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

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      expectMemNameOnMemDetail(widgetTester, enteringMemName);
      expectMemMemoOnMemDetail(widgetTester, enteringMemMemo);

      verifyNever(mockedMemRepositoryV2.shipByCondition(any, any));
      verifyNever(mockedMemItemRepository.shipByMemId(any));

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, '');
      expectMemMemoOnMemDetail(widgetTester, '');
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Update mem',
    (widgetTester) async {
      final savedMem = minSavedMem(1);
      when(mockedMemRepositoryV2.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);

      verify(mockedMemRepositoryV2.shipByCondition(false, false)).called(1);

      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemoMemItemEntity = minSavedMemoMemItemEntity(
        savedMem.id,
        1,
      )
        ..type = MemItemType.memo
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(find.text(savedMem.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      verifyNever(mockedMemRepository.shipById(any));
      verify(mockedMemItemRepository.shipByMemId(savedMem.id)).called(1);

      expectMemNameOnMemDetail(widgetTester, savedMem.name);
      expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      expect(find.text(savedMem.name), findsOneWidget);
      expect(find.text(savedMemoMemItemEntity.value), findsOneWidget);

      const enteringMemName = 'updating mem name';
      const enteringMemMemo = 'updating mem memo';

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);

      when(mockedMemRepositoryV2.replace(any)).thenAnswer((realInvocation) {
        final mem = realInvocation.positionalArguments[0] as Mem;

        expect(mem.name, enteringMemName);
        expect(mem.id, savedMem.id);
        expect(mem.createdAt, savedMem.createdAt);
        expect(mem.updatedAt, null);
        expect(mem.archivedAt, null);

        return Future.value(Mem(
          name: mem.name,
          id: mem.id,
          createdAt: mem.createdAt,
          updatedAt: mem.updatedAt,
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

      verify(mockedMemRepositoryV2.replace(any)).called(1);
      verify(mockedMemItemRepository.update(any)).called(1);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      verifyNever(mockedMemRepositoryV2.shipByCondition(any, any));

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Archive mem',
    (widgetTester) async {
      final savedMem = minSavedMem(1)..name = 'saved mem entity';
      when(mockedMemRepositoryV2.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemoMemItemEntity = minSavedMemoMemItemEntity(savedMem.id, 1)
        ..type = MemItemType.memo
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(find.text(savedMem.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      verify(mockedMemRepositoryV2.shipByCondition(false, false)).called(1);

      when(mockedMemRepositoryV2.archive(any)).thenAnswer((realInvocation) {
        final mem = realInvocation.positionalArguments[0] as Mem;

        return Future.value(mem..archivedAt = DateTime.now());
      });
      when(mockedMemItemRepository.archiveByMemId(savedMem.id))
          .thenAnswer((realInvocation) {
        final memId = realInvocation.positionalArguments[0] as int;

        expect(memId, savedMem.id);

        return Future.value([savedMemoMemItemEntity]
            .map((e) => e..archivedAt = DateTime.now())
            .toList());
      });

      await widgetTester.tap(archiveButtonFinder);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepositoryV2.archive(any)).called(1);
      verify(mockedMemItemRepository.archiveByMemId(savedMem.id)).called(1);

      expect(widgetTester.widgetList(memListTileFinder).length, 0);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Remove mem and undo',
    (widgetTester) async {
      final savedMem = minSavedMem(1)..name = 'saved mem entity';
      when(mockedMemRepositoryV2.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      final savedMemoMemItemEntity = minSavedMemoMemItemEntity(savedMem.id, 1)
        ..type = MemItemType.memo
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      when(mockedMemItemRepository.discardByMemId(savedMem.id))
          .thenAnswer((realInvocation) => Future.value([true]));
      when(mockedMemRepository.discardById(savedMem.id))
          .thenAnswer((realInvocation) => Future.value(true));

      await widgetTester.tap(memDetailMenuButtonFinder);
      await widgetTester.pumpAndSettle();
      await widgetTester.tap(removeButtonFinder);
      await widgetTester.pump();
      await widgetTester.tap(okButtonFinder);
      await widgetTester.pump(); // start animation
      await widgetTester.pump();
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      expect(widgetTester.widgetList(memListTileFinder).length, 0);
      expect(find.text(savedMem.name), findsNothing);
      expect(
        find.text('Remove success. ${savedMem.name}'),
        findsOneWidget,
      );
      expect(
        find.text('Undo'),
        findsOneWidget,
      );

      when(mockedMemRepositoryV2.receive(any)).thenAnswer((realInvocation) {
        final arg1 = realInvocation.positionalArguments[0];

        return Future.value(minSavedMem(arg1.id)..name = arg1.name);
      });
      when(mockedMemItemRepository.receive(any)).thenAnswer((realInvocation) {
        final arg1 = realInvocation.positionalArguments[0];

        expect(arg1, isA<MemItemEntity>());
        expect(arg1.id, savedMemoMemItemEntity.id);

        return Future.value(savedMemoMemItemEntity);
      });

      await widgetTester.tap(find.text('Undo'));
      await widgetTester.pump();
      await widgetTester.pumpAndSettle();

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expect(find.text(savedMem.name), findsOneWidget);
      expect(
        find.text('Save success. ${savedMem.name}'),
        findsOneWidget,
      );
    },
    tags: TestSize.small,
  );
}
