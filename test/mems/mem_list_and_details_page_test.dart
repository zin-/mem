import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mockito/mockito.dart';

import '../samples.dart';
import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';
import 'mem_list_page_test.dart';
import 'mem_detail_menu_test.dart';
import 'mem_detail_body_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.resetWith(mockedMemItemRepository);

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

      when(mockedMemRepository.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepository.shipByCondition(false, false)).called(1);

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);
      await widgetTester.pump();

      const memId = 1;
      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) {
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
        final memItem = realInvocation.positionalArguments[0] as MemItem;

        expect(memItem.memId, memId);
        expect(memItem.type, MemItemType.memo);
        expect(memItem.value, enteringMemMemo);
        expect(memItem.id, null);
        expect(memItem.createdAt, null);
        expect(memItem.updatedAt, null);
        expect(memItem.archivedAt, null);

        return Future.value(minSavedMemItem(memId, memItemId)
          ..value = enteringMemMemo
          ..createdAt = DateTime.now());
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

      verifyNever(mockedMemRepository.shipByCondition(any, any));
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
      final savedMem = minSavedMem(1);
      when(mockedMemRepository.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);

      verify(mockedMemRepository.shipByCondition(false, false)).called(1);

      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemItem = minSavedMemItem(
        savedMem.id,
        1,
      )..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(any))
          .thenAnswer((realInvocation) => Future.value([savedMemItem]));

      await widgetTester.tap(find.text(savedMem.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      verifyNever(mockedMemRepository.shipById(any));
      verify(mockedMemItemRepository.shipByMemId(savedMem.id)).called(1);

      expectMemNameOnMemDetail(widgetTester, savedMem.name);
      expectMemMemoOnMemDetail(widgetTester, savedMemItem.value);
      expect(find.text(savedMem.name), findsOneWidget);
      expect(find.text(savedMemItem.value), findsOneWidget);

      const enteringMemName = 'updating mem name';
      const enteringMemMemo = 'updating mem memo';

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);

      when(mockedMemRepository.replace(any)).thenAnswer((realInvocation) {
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
      when(mockedMemItemRepository.replace(any)).thenAnswer((realInvocation) {
        final memItem = realInvocation.positionalArguments[0] as MemItem;

        expect(memItem.memId, savedMemItem.memId);
        expect(memItem.type, savedMemItem.type);
        expect(memItem.value, enteringMemMemo);
        expect(memItem.id, savedMemItem.id);
        expect(memItem.createdAt, savedMemItem.createdAt);
        expect(memItem.updatedAt, null);
        expect(memItem.archivedAt, null);

        return Future.value(
          minSavedMemItem(savedMemItem.memId!, savedMemItem.id)
            ..value = memItem.value
            ..createdAt = savedMemItem.createdAt
            ..updatedAt = DateTime.now(),
        );
      });

      await widgetTester.tap(saveFabFinder);

      verify(mockedMemRepository.replace(any)).called(1);
      verify(mockedMemItemRepository.replace(any)).called(1);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      verifyNever(mockedMemRepository.shipByCondition(any, any));

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    },
  );

  testWidgets(
    'Archive mem',
    (widgetTester) async {
      final savedMem = minSavedMem(1)..name = 'saved mem entity';
      when(mockedMemRepository.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemoMemItem = minSavedMemItem(savedMem.id, 1)
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMem.id))
          .thenAnswer((realInvocation) => Future.value([savedMemoMemItem]));

      await widgetTester.tap(find.text(savedMem.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      verify(mockedMemRepository.shipByCondition(false, false)).called(1);

      when(mockedMemRepository.archive(any)).thenAnswer((realInvocation) {
        final mem = realInvocation.positionalArguments[0] as Mem;

        return Future.value(mem..archivedAt = DateTime.now());
      });
      when(mockedMemItemRepository.archiveByMemId(savedMem.id))
          .thenAnswer((realInvocation) {
        final memId = realInvocation.positionalArguments[0] as int;

        expect(memId, savedMem.id);

        return Future.value([savedMemoMemItem]
            .map((e) => e..archivedAt = DateTime.now())
            .toList());
      });

      await widgetTester.tap(archiveButtonFinder);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepository.archive(any)).called(1);
      verify(mockedMemItemRepository.archiveByMemId(savedMem.id)).called(1);

      expect(widgetTester.widgetList(memListTileFinder).length, 0);
    },
  );

  testWidgets(
    'Remove mem and undo',
    (widgetTester) async {
      final savedMem = minSavedMem(1)..name = 'saved mem entity';
      when(mockedMemRepository.shipByCondition(any, any))
          .thenAnswer((realInvocation) => Future.value([savedMem]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      final savedMemItem = minSavedMemItem(savedMem.id, 1)
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMem.id))
          .thenAnswer((realInvocation) => Future.value([savedMemItem]));

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      when(mockedMemItemRepository.wasteByMemId(savedMem.id))
          .thenAnswer((realInvocation) => Future.value([savedMemItem]));
      when(mockedMemRepository.wasteById(savedMem.id))
          .thenAnswer((realInvocation) => Future.value(savedMem));

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

      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) {
        final arg1 = realInvocation.positionalArguments[0];

        return Future.value(minSavedMem(arg1.id)..name = arg1.name);
      });
      when(mockedMemItemRepository.receive(any)).thenAnswer((realInvocation) {
        final arg1 = realInvocation.positionalArguments[0];

        expect(arg1, isA<MemItem>());
        expect(arg1.id, savedMemItem.id);

        return Future.value(savedMemItem);
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
  );
}
