import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/act_counter/select_mem_fab.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/mems/mem_list_view_state.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../helpers.dart';
import '../helpers.mocks.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      'selectedMemIds is empty',
      (widgetTester) async {
        await runTestWidgetWithProvider(
          widgetTester,
          const SelectMemFab(),
        );

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          widgetTester
              .firstWidget<FloatingActionButton>(
                  find.byType(FloatingActionButton))
              .backgroundColor,
          Colors.grey,
        );
      },
    );

    testWidgets(
      'selectedMemIds is not empty',
      (widgetTester) async {
        await runTestWidgetWithProvider(
          widgetTester,
          const SelectMemFab(),
          overrides: [
            selectedMemIdsProvider
                .overrideWith((ref) => ListValueStateNotifier([1])),
          ],
        );

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          widgetTester
              .firstWidget<FloatingActionButton>(
                  find.byType(FloatingActionButton))
              .backgroundColor,
          null,
        );
      },
    );
  });

  group('Actions', () {
    final mockedActCounterService = MockActCounterService();
    ActCounterService.resetWith(mockedActCounterService);

    testWidgets(
      ': tap',
      (widgetTester) async {
        final selectedMemId = randomInt();

        when(mockedActCounterService.createNew(selectedMemId))
            .thenAnswer((realInvocation) => Future.value(null));

        await runTestWidgetWithProvider(
          widgetTester,
          const SelectMemFab(),
          overrides: [
            selectedMemIdsProvider
                .overrideWith((ref) => ListValueStateNotifier([selectedMemId])),
          ],
        );

        await widgetTester.tap(find.byType(SelectMemFab));

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          widgetTester
              .firstWidget<FloatingActionButton>(
                  find.byType(FloatingActionButton))
              .backgroundColor,
          null,
        );

        verify(mockedActCounterService.createNew(any)).called(1);
      },
    );
  });
}
