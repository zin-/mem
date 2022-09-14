import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/database.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/constants.dart';

import '../mocks.mocks.dart';

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

  group('Show', () {
    testWidgets(': not found.', (widgetTester) async {
      const memId = 1;

      when(mockedMemRepository.shipById(memId))
          .thenThrow(NotFoundException('test target', 'test condition'));

      await pumpMemDetailPage(widgetTester, memId);

      verify(mockedMemRepository.shipById(memId)).called(1);
      verifyNever(mockedMemItemRepository.shipByMemId(any));

      expectMemNameOnMemDetail(widgetTester, '');
      expectMemMemoOnMemDetail(widgetTester, '');
      expect(saveFabFinder, findsOneWidget);
    });

    testWidgets(': found.', (widgetTester) async {
      final savedMemEntity = MemEntity(
        name: 'saved mem entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemRepository.shipById(savedMemEntity.id))
          .thenAnswer((realInvocation) async => savedMemEntity);
      final savedMemoMemItemEntity = MemItemEntity(
        memId: savedMemEntity.id,
        type: MemItemType.memo,
        value: 'saved memo mem item entity',
        id: 1,
        createdAt: DateTime.now(),
      );
      when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
          (realInvocation) => Future.value([savedMemoMemItemEntity]));

      await pumpMemDetailPage(widgetTester, savedMemEntity.id);

      verify(mockedMemRepository.shipById(savedMemEntity.id)).called(1);
      verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).called(1);

      await widgetTester.pumpAndSettle();

      expectMemNameOnMemDetail(widgetTester, savedMemEntity.name);
      expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      expect(find.text(savedMemEntity.name), findsOneWidget);
      expect(find.text(savedMemoMemItemEntity.value), findsOneWidget);
      expect(saveFabFinder, findsOneWidget);
    });
  });

  testWidgets(
    ': archived.',
    (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';

      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) async => MemEntity(
                id: memId,
                name: memName,
                createdAt: DateTime.now(),
                archivedAt: DateTime.now(),
              ));

      await pumpMemDetailPage(widgetTester, memId);
      await widgetTester.pump();

      verify(mockedMemRepository.shipById(memId)).called(1);
    },
  );

  group('Edit', () {
    testWidgets(
      ': keep focus mem name.',
      (widgetTester) async {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          // dev('object');
          // dev(focusNode.hasFocus);
          // dev(focusNode.hasPrimaryFocus);
          if (focusNode.hasFocus && focusNode.hasPrimaryFocus) {
          } else {
            fail('out of focus on mem name');
          }
        });
        await pumpMemDetailPage(widgetTester, null);

        expect(focusNode.hasPrimaryFocus, false);

        await widgetTester.tap(memNameTextFormFieldFinder);

        expect(focusNode.hasPrimaryFocus, true);

        await widgetTester.enterText(
          memNameTextFormFieldFinder,
          'entering mem name',
        );
        await widgetTester.pumpAndSettle();

        // FIXME ここで、フォーカスがはずれていることを確認したかったが、確認できなかった
        expect(focusNode.hasPrimaryFocus, true);
      },
      skip: true,
    );

    testWidgets(': memo', (widgetTester) async {
      await pumpMemDetailPage(widgetTester, null);

      expect(memMemoTextFormFieldFinder, findsOneWidget);
      const enteringMemMemo = 'test mem memo';
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);

      expect(find.text(enteringMemMemo), findsOneWidget);
    });
  });

  group('Save', () {
    testWidgets(': name is required.', (widgetTester) async {
      await pumpMemDetailPage(widgetTester, null);

      await widgetTester.tap(saveFabFinder);

      expect(find.text('Name is required'), findsNothing);

      verifyNever(mockedMemRepository.shipById(any));
      verifyNever(mockedMemRepository.receiveV1(any));
    });

    testWidgets(': create.', (widgetTester) async {
      const enteringMemName = 'entering mem name';
      const enteringMemMemo = 'test mem memo';
      const memId = 1;

      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0] as MemEntity;
        expect(value.name, enteringMemName);

        return MemEntity(
          id: memId,
          name: value.name,
          createdAt: DateTime.now(),
        );
      });
      when(mockedMemItemRepository.receive(any))
          .thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0] as MemItemEntity;
        expect(value.memId, memId);
        expect(value.type, MemItemType.memo);
        expect(value.value, enteringMemMemo);

        return MemItemEntity(
          id: 1,
          memId: memId,
          type: MemItemType.memo,
          value: enteringMemMemo,
          createdAt: DateTime.now(),
        );
      });

      await pumpMemDetailPage(widgetTester, null);

      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);
      await enterMemNameAndSave(widgetTester, enteringMemName);

      await checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

      verifyNever(mockedMemRepository.shipById(any));
      verify(mockedMemRepository.receive(any)).called(1);
      verify(mockedMemItemRepository.receive(any)).called(1);
    });

    testWidgets(': update.', (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) async => MemEntity(
                name: memName,
                id: memId,
                createdAt: DateTime.now(),
              ));
      const memItemId = 1;
      const memMemo = 'test mem memo';
      when(mockedMemItemRepository.shipByMemId(any))
          .thenAnswer((realInvocation) async => [
                MemItemEntity(
                  memId: memId,
                  type: MemItemType.memo,
                  value: memMemo,
                  id: memItemId,
                  createdAt: DateTime.now(),
                )
              ]);

      await pumpMemDetailPage(widgetTester, memId);
      await widgetTester.pump();

      verify(mockedMemRepository.shipById(memId)).called(1);
      verify(mockedMemItemRepository.shipByMemId(memId)).called(1);

      const enteringMemName = 'entering mem name';
      const enteringMemMemo = 'entering mem memo';

      await widgetTester.enterText(memNameTextFormFieldFinder, enteringMemName);
      await widgetTester.enterText(memMemoTextFormFieldFinder, enteringMemMemo);

      when(mockedMemRepository.update(any)).thenAnswer((realInvocation) async {
        final memEntity = realInvocation.positionalArguments[0] as MemEntity;
        expect(memEntity.id, memId);
        expect(memEntity.name, enteringMemName);
        expect(memEntity.createdAt, isNotNull);
        expect(memEntity.updatedAt, isNull);
        expect(memEntity.archivedAt, isNull);

        return memEntity..updatedAt = DateTime.now();
      });
      when(mockedMemItemRepository.update(any))
          .thenAnswer((realInvocation) async {
        final memItemEntity =
            realInvocation.positionalArguments[0] as MemItemEntity;
        expect(memItemEntity.memId, memId);
        expect(memItemEntity.type, MemItemType.memo);
        expect(memItemEntity.value, enteringMemMemo);
        expect(memItemEntity.createdAt, isNotNull);
        expect(memItemEntity.updatedAt, isNull);
        expect(memItemEntity.archivedAt, isNull);

        return memItemEntity..updatedAt = DateTime.now();
      });

      await widgetTester.tap(saveFabFinder);
      await widgetTester.pumpAndSettle();

      verify(mockedMemRepository.update(any)).called(1);
      verify(mockedMemItemRepository.update(any)).called(1);

      checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);
    });
  });
}

Future pumpMemDetailPage(
  WidgetTester widgetTester,
  int? memId,
) async {
  await widgetTester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        onGenerateTitle: (context) => L10n(context).memDetailPageTitle(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MemDetailPage(memId),
      ),
    ),
  );
  await widgetTester.pumpAndSettle();
}

final memNameTextFormFieldFinder = find.byType(TextFormField).at(0);
final memMemoTextFormFieldFinder = find.byType(TextFormField).at(1);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);

TextFormField memNameTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField);

TextFormField memMemoTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memMemoTextFormFieldFinder) as TextFormField);

void expectMemNameOnMemDetail(
  WidgetTester widgetTester,
  String memName,
) =>
    expect(
      memNameTextFormField(widgetTester).initialValue,
      memName,
    );

void expectMemMemoOnMemDetail(
  WidgetTester widgetTester,
  String memMemo,
) =>
    expect(
      memMemoTextFormField(widgetTester).initialValue,
      memMemo,
    );

Future<void> enterMemNameAndSave(
  WidgetTester widgetTester,
  String enteringText,
) async {
  await widgetTester.enterText(memNameTextFormFieldFinder, enteringText);
  await widgetTester.tap(saveFabFinder);
  await widgetTester.pumpAndSettle();
}

Future<void> checkSavedSnackBarAndDismiss(
  WidgetTester widgetTester,
  String memName,
) async {
  expect(saveMemSuccessFinder(memName), findsOneWidget);

  await widgetTester.pumpAndSettle(defaultDismissDuration);

  expect(saveMemSuccessFinder(memName), findsNothing);
}

Finder saveMemSuccessFinder(String memName) =>
    find.text('Save success. $memName');
