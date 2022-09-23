import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_body.dart';
import 'package:mockito/mockito.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/database.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/constants.dart';

import '../../minimum.dart';
import '../../mocks.mocks.dart';

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
    testWidgets(
      ': not found Mem',
      (widgetTester) async {
        const memId = 1;

        when(mockedMemRepository.shipById(memId))
            .thenThrow(NotFoundException('test target', 'test condition'));

        await pumpMemDetailPage(widgetTester, memId);

        verify(mockedMemRepository.shipById(memId)).called(1);

        expect(find.byType(MemDetailBody), findsOneWidget);
        expect(saveFabFinder, findsOneWidget);
      },
      tags: 'Small',
    );

    testWidgets(
      ': found Mem',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1);
        when(mockedMemRepository.shipById(savedMemEntity.id))
            .thenAnswer((realInvocation) async => savedMemEntity);
        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1);
        when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        await pumpMemDetailPage(widgetTester, savedMemEntity.id);

        verify(mockedMemRepository.shipById(savedMemEntity.id)).called(1);
        verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id))
            .called(1);

        await widgetTester.pumpAndSettle();

        expect(find.byType(MemDetailBody), findsOneWidget);
        expect(saveFabFinder, findsOneWidget);
      },
      tags: 'Small',
    );
  });

  group('Save', () {
    testWidgets(
      ': name is required.',
      (widgetTester) async {
        await pumpMemDetailPage(widgetTester, null);

        await widgetTester.tap(saveFabFinder);

        expect(find.text('Name is required'), findsNothing);

        verifyNever(mockedMemRepository.shipById(any));
        verifyNever(mockedMemRepository.receive(any));
      },
      tags: 'Small',
    );

    testWidgets(
      ': create.',
      (widgetTester) async {
        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'test mem memo';
        const memId = 1;

        when(mockedMemRepository.receive(any))
            .thenAnswer((realInvocation) async {
          final value = realInvocation.positionalArguments[0] as MemEntity;
          expect(value.name, enteringMemName);

          return minSavedMemEntity(memId)..name = value.name;
        });
        when(mockedMemItemRepository.receive(any))
            .thenAnswer((realInvocation) async {
          final value = realInvocation.positionalArguments[0] as MemItemEntity;
          expect(value.memId, memId);
          expect(value.type, MemItemType.memo);
          expect(value.value, enteringMemMemo);

          return minSavedMemoMemItemEntity(memId, 1)
            ..type = value.type
            ..value = value.value;
        });

        await pumpMemDetailPage(widgetTester, null);

        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);
        await enterMemNameAndSave(widgetTester, enteringMemName);

        await checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

        verifyNever(mockedMemRepository.shipById(any));
        verify(mockedMemRepository.receive(any)).called(1);
        verify(mockedMemItemRepository.receive(any)).called(1);
      },
      tags: 'Small',
    );

    testWidgets(
      ': update.',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1);
        when(mockedMemRepository.shipById(savedMemEntity.id))
            .thenAnswer((realInvocation) async => savedMemEntity);
        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1);
        when(mockedMemItemRepository.shipByMemId(any))
            .thenAnswer((realInvocation) async => [savedMemoMemItemEntity]);

        await pumpMemDetailPage(widgetTester, savedMemEntity.id);
        await widgetTester.pump();

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        when(mockedMemRepository.update(any))
            .thenAnswer((realInvocation) async {
          final memEntity = realInvocation.positionalArguments[0] as MemEntity;
          expect(memEntity.id, minMemEntity.id);
          expect(memEntity.name, enteringMemName);
          expect(memEntity.createdAt, minMemEntity.createdAt);
          expect(memEntity.updatedAt, minMemEntity.updatedAt);
          expect(memEntity.archivedAt, minMemEntity.archivedAt);

          return memEntity..updatedAt = DateTime.now();
        });
        when(mockedMemItemRepository.update(any))
            .thenAnswer((realInvocation) async {
          final memItemEntity =
              realInvocation.positionalArguments[0] as MemItemEntity;
          expect(memItemEntity.memId, savedMemoMemItemEntity.memId);
          expect(memItemEntity.type, savedMemoMemItemEntity.type);
          expect(memItemEntity.value, enteringMemMemo);
          expect(memItemEntity.createdAt, savedMemoMemItemEntity.createdAt);
          expect(memItemEntity.updatedAt, savedMemoMemItemEntity.updatedAt);
          expect(memItemEntity.archivedAt, savedMemoMemItemEntity.archivedAt);

          return memItemEntity..updatedAt = DateTime.now();
        });

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle();

        verify(mockedMemRepository.update(any)).called(1);
        verify(mockedMemItemRepository.update(any)).called(1);

        checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);
      },
      tags: 'Small',
    );
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
