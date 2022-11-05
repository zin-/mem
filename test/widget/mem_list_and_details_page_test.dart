import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../samples.dart';
import '../mocks.mocks.dart';
import 'mem_detail/mem_detail_page_test.dart';
import 'mem_list/mem_list_page_test.dart';
import 'mem_detail/mem_detail_menu_test.dart';
import 'mem_detail/mem_detail_body_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
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

      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer((realInvocation) => Future.value([]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).called(1);

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);
      await widgetTester.pump();

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

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      expectMemNameOnMemDetail(widgetTester, enteringMemName);
      expectMemMemoOnMemDetail(widgetTester, enteringMemMemo);

      verifyNever(mockedMemRepository.ship(whereMap: anyNamed('whereMap')));
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
      final savedMemEntity = minSavedMemEntity(1)..name = 'saved mem entity';
      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer((realInvocation) => Future.value([savedMemEntity]));

      await pumpMemListPage(widgetTester);
      verify(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).called(1);

      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemoMemItemEntity = minSavedMemoMemItemEntity(
        savedMemEntity.id,
        1,
      )
        ..type = MemItemType.memo
        ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(find.text(savedMemEntity.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      verifyNever(mockedMemRepository.shipById(any));
      verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).called(1);

      expectMemNameOnMemDetail(widgetTester, savedMemEntity.name);
      expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      expect(find.text(savedMemEntity.name), findsOneWidget);
      expect(find.text(savedMemoMemItemEntity.value), findsOneWidget);

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

      verifyNever(mockedMemRepository.ship(whereMap: anyNamed('whereMap')));

      expect(widgetTester.widgetList(memListTileFinder).length, 1);
      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Archive mem',
    (widgetTester) async {
      final savedMemEntity = minSavedMemEntity(1)..name = 'saved mem entity';
      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer((realInvocation) => Future.value([savedMemEntity]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      final savedMemoMemItemEntity =
          minSavedMemoMemItemEntity(savedMemEntity.id, 1)
            ..type = MemItemType.memo
            ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(find.text(savedMemEntity.name));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      verify(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).called(1);

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
    tags: TestSize.small,
  );

  testWidgets(
    'Remove mem and undo',
    (widgetTester) async {
      final savedMemEntity = minSavedMemEntity(1)..name = 'saved mem entity';
      when(mockedMemRepository.ship(
        whereMap: anyNamed('whereMap'),
        archive: anyNamed('archive'),
        done: anyNamed('done'),
      )).thenAnswer((realInvocation) => Future.value([savedMemEntity]));

      await pumpMemListPage(widgetTester);
      await widgetTester.pumpAndSettle();

      final savedMemoMemItemEntity =
          minSavedMemoMemItemEntity(savedMemEntity.id, 1)
            ..type = MemItemType.memo
            ..value = 'saved memo mem item entity';
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      when(mockedMemItemRepository.discardByMemId(savedMemEntity.id))
          .thenAnswer((realInvocation) => Future.value([true]));
      when(mockedMemRepository.discardById(savedMemEntity.id))
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
      expect(find.text(savedMemEntity.name), findsNothing);
      expect(
        find.text('Remove success. ${savedMemEntity.name}'),
        findsOneWidget,
      );
      expect(
        find.text('Undo'),
        findsOneWidget,
      );

      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) {
        final arg1 = realInvocation.positionalArguments[0];

        expect(arg1, isA<MemEntity>());
        expect(arg1.id, savedMemEntity.id);

        return Future.value(savedMemEntity);
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
      expect(find.text(savedMemEntity.name), findsOneWidget);
      expect(
        find.text('Save success. ${savedMemEntity.name}'),
        findsOneWidget,
      );
    },
    tags: TestSize.small,
  );
}
