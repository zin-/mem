import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_body.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';
import 'package:mockito/mockito.dart';

import '../../samples.dart';
import '../../mocks.mocks.dart';

void main() {
  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.reset(mockedMemItemRepository);

  tearDown(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
  });

  Future pumpMemDetailBody(
    WidgetTester widgetTester,
    int? memId, {
    Mem? mem,
  }) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          memProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider((ref) => ValueStateNotifier(mem));
          }),
          editingMemProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider(
                (ref) => ValueStateNotifier(mem ?? minMem()));
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
        final mem = minMem()
          ..name = ''
          ..doneAt = null;

        await pumpMemDetailBody(widgetTester, null, mem: mem);

        verifyNever(mockedMemRepository.shipById(any));
        verifyNever(mockedMemItemRepository.shipByMemId(any));

        await widgetTester.pumpAndSettle();

        expectMemNameOnMemDetail(widgetTester, mem.name);
        expectMemDoneOnMemDetail(widgetTester, false);
        expectMemMemoOnMemDetail(widgetTester, '');
      },
      tags: 'Small',
    );

    testWidgets(
      ': saved',
      (widgetTester) async {
        const memId = 1;
        final savedMem = minSavedMem(memId)
          ..name = 'saved mem name'
          ..doneAt = DateTime.now();

        final savedMemoMemItemEntity = minSavedMemoMemItemEntity(memId, 1);
        when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        await pumpMemDetailBody(
          widgetTester,
          savedMem.id,
          mem: savedMem,
        );

        verifyNever(mockedMemRepository.shipById(any));
        verify(mockedMemItemRepository.shipByMemId(savedMem.id)).called(1);

        await widgetTester.pumpAndSettle();

        expectMemNameOnMemDetail(widgetTester, savedMem.name);
        expectMemDoneOnMemDetail(widgetTester, true);
        expectMemMemoOnMemDetail(widgetTester, savedMemoMemItemEntity.value);
      },
      tags: 'Small',
    );

    testWidgets(
      ': found unarchived Mem with archived MemItems',
      (widgetTester) async {
        const memId = 1;
        final savedMem = minSavedMem(memId)..name = 'saved mem name';
        final savedMemoMemItemEntity = minSavedMemoMemItemEntity(memId, 1)
          ..archivedAt = DateTime.now();
        when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        await pumpMemDetailBody(
          widgetTester,
          savedMem.id,
          mem: savedMem,
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
        final mem = minMem()..doneAt = null;

        await pumpMemDetailBody(widgetTester, null, mem: mem);
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
final memMemoTextFormFieldFinder = find.byType(TextFormField).at(2);

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
