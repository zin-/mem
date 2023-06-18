import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/mems/mem_detail_states.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_items_view.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/mems/mem_detail_body.dart';
import 'package:mem/mems/mem_done_checkbox.dart';
import 'package:mockito/mockito.dart';

import '../helpers.mocks.dart';
import '../samples.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.resetWith(mockedMemItemRepository);

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
    );

    testWidgets(
      ': saved',
      (widgetTester) async {
        const memId = 1;
        final savedMem = minSavedMem(memId)
          ..name = 'saved mem name'
          ..doneAt = DateTime.now();

        final savedMemItem = minSavedMemItem(memId, 1)
          ..value = 'saved mem item';
        when(mockedMemItemRepository.shipByMemId(savedMem.id))
            .thenAnswer((realInvocation) => Future.value([savedMemItem]));

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
        expectMemMemoOnMemDetail(widgetTester, savedMemItem.value);
      },
    );

    testWidgets(
      ': found unarchived Mem with archived MemItems',
      (widgetTester) async {
        const memId = 1;
        final savedMem = minSavedMem(memId)..name = 'saved mem name';
        final savedMemItem = minSavedMemItem(memId, 1)
          ..value = 'archived mem item'
          ..archivedAt = DateTime.now();
        when(mockedMemItemRepository.shipByMemId(savedMem.id))
            .thenAnswer((realInvocation) => Future.value([savedMemItem]));

        await pumpMemDetailBody(
          widgetTester,
          savedMem.id,
          mem: savedMem,
        );

        await widgetTester.pumpAndSettle();

        expectMemMemoOnMemDetail(widgetTester, savedMemItem.value);
      },
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
    );

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
    );
  });
}

final memNameTextFormFieldFinder = find.descendant(
  of: find.descendant(
    of: find.byType(MemDetailBody),
    matching: find.byType(MemNameTextFormField),
  ),
  matching: find.byType(TextFormField),
);
final memDoneCheckboxFinder = find.descendant(
  of: find.descendant(
    of: find.byType(MemDetailBody),
    matching: find.byType(MemDoneCheckbox),
  ),
  matching: find.byType(Checkbox),
);
final memMemoTextFormFieldFinder = find.descendant(
  of: find.descendant(
    of: find.byType(MemDetailBody),
    matching: find.byType(MemItemsViewComponent),
  ),
  matching: find.byType(TextFormField),
);

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
