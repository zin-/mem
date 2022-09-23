import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/views/mem_detail/mem_detail_body.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mockito/mockito.dart';

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

  Future pumpMemDetailBody(
    WidgetTester widgetTester,
    int? memId, {
    MemEntity? memEntity,
  }) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          memProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider(
                (ref) => ValueStateNotifier(memEntity));
          }),
          editingMemProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider(
                (ref) => ValueStateNotifier(memEntity ?? minMemEntity));
          }),
          memItemsProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider((ref) => ListValueStateNotifier(null));
          }),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => L10n(context).memDetailPageTitle(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MemDetailBody(memId),
          ),
        ),
      ),
    );
  }

  group('Show', () {
    testWidgets(
      ': empty',
      (widgetTester) async {
        final memEntity = minMemEntity
          ..name = ''
          ..doneAt = null;

        await pumpMemDetailBody(widgetTester, null, memEntity: memEntity);

        verifyNever(mockedMemRepository.shipById(any));
        verifyNever(mockedMemItemRepository.shipByMemId(any));

        await widgetTester.pumpAndSettle();

        expectMemNameOnMemDetail(widgetTester, memEntity.name);
        expectMemDoneOnMemDetail(widgetTester, false);
        expectMemMemoOnMemDetail(widgetTester, '');
      },
      tags: 'Small',
    );

    testWidgets(
      ': saved',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1)
          ..name = 'saved mem name'
          ..doneAt = DateTime.now();

        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1);
        when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        await pumpMemDetailBody(
          widgetTester,
          savedMemEntity.id,
          memEntity: savedMemEntity,
        );

        verifyNever(mockedMemRepository.shipById(any));
        verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id))
            .called(1);

        await widgetTester.pumpAndSettle();

        expectMemNameOnMemDetail(widgetTester, savedMemEntity.name);
        expectMemDoneOnMemDetail(widgetTester, true);
        expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      },
      tags: 'Small',
    );

    testWidgets(
      ': found unarchived Mem with archived MemItems',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1)..name = 'saved mem name';
        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1)
              ..archivedAt = DateTime.now();
        when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        await pumpMemDetailBody(
          widgetTester,
          savedMemEntity.id,
          memEntity: savedMemEntity,
        );

        await widgetTester.pumpAndSettle();

        expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      },
      tags: 'Small',
    );
  });

  group('Edit', () {
    testWidgets(
      ': name',
      (widgetTester) async {
        await pumpMemDetailBody(widgetTester, null);
        await widgetTester.pumpAndSettle();

        expect(memMemoTextFormFieldFinder, findsOneWidget);

        const enteringMemMemo = 'entering mem name';
        await widgetTester.enterText(
          memNameTextFormFieldFinder,
          enteringMemMemo,
        );

        expect(find.text(enteringMemMemo), findsOneWidget);
      },
      tags: 'Small',
    );

    // testWidgets(
    //   ': keep focus mem name.',
    //   (widgetTester) async {
    //     final focusNode = FocusNode();
    //     focusNode.addListener(() {
    //       // dev('object');
    //       // dev(focusNode.hasFocus);
    //       // dev(focusNode.hasPrimaryFocus);
    //       if (focusNode.hasFocus && focusNode.hasPrimaryFocus) {
    //       } else {
    //         fail('out of focus on mem name');
    //       }
    //     });
    //     await pumpMemDetailPage(widgetTester, null);
    //
    //     expect(focusNode.hasPrimaryFocus, false);
    //
    //     await widgetTester.tap(memNameTextFormFieldFinder);
    //
    //     expect(focusNode.hasPrimaryFocus, true);
    //
    //     await widgetTester.enterText(
    //       memNameTextFormFieldFinder,
    //       'entering mem name',
    //     );
    //     await widgetTester.pumpAndSettle();
    //
    //     // FIXME ここで、フォーカスがはずれていることを確認したかったが、確認できなかった
    //     expect(focusNode.hasPrimaryFocus, true);
    //   },
    //   tags: 'Small',
    //   skip: true,
    // );

    testWidgets(
      ': done',
      (widgetTester) async {
        final memEntity = minMemEntity..doneAt = null;

        await pumpMemDetailBody(widgetTester, null, memEntity: memEntity);
        await widgetTester.pumpAndSettle();

        expectMemDoneOnMemDetail(widgetTester, false);

        await widgetTester.tap(memDoneCheckboxFinder);
        await widgetTester.pump();

        expectMemDoneOnMemDetail(widgetTester, true);
      },
      tags: 'Small',
    );

    testWidgets(
      ': memo',
      (widgetTester) async {
        await pumpMemDetailBody(widgetTester, null);
        await widgetTester.pumpAndSettle();

        expect(memMemoTextFormFieldFinder, findsOneWidget);
        const enteringMemMemo = 'entering mem memo';
        await widgetTester.enterText(
          memMemoTextFormFieldFinder,
          enteringMemMemo,
        );

        expect(find.text(enteringMemMemo), findsOneWidget);
      },
      tags: 'Small',
    );
  });
}

final memNameTextFormFieldFinder = find.byType(TextFormField).at(0);
final memDoneCheckboxFinder = find.byType(Checkbox);
final memMemoTextFormFieldFinder = find.byType(TextFormField).at(1);

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

void expectMemDoneOnMemDetail(
  WidgetTester widgetTester,
  bool memDone,
) =>
    expect(
      (widgetTester.widget(memDoneCheckboxFinder) as Checkbox).value,
      memDone,
    );

void expectMemMemoOnMemDetail(
  WidgetTester widgetTester,
  String memMemo,
) =>
    expect(
      memMemoTextFormField(widgetTester).initialValue,
      memMemo,
    );
