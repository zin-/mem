import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/act_counter/select_mem_fab.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/mems/mem_list_view_state.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import 'select_mem_fab_test.mocks.dart';

@GenerateMocks([
  ActCounterService,
])
void main() {
  initializeLogger(Level.error);

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
      tags: TestSize.small,
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
      tags: TestSize.small,
    );
  });

  group('Actions', () {
    final mockedActCounterService = MockActCounterService();
    ActCounterService.resetWith(mockedActCounterService);

    testWidgets(
      ': tap',
      (widgetTester) async {
        final selectedMemId = math.Random().nextInt(4294967296);

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
      tags: TestSize.small,
    );
  });
}
