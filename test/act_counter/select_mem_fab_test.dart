import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/counter/act_counter_client.dart';
import 'package:mem/features/acts/counter/select_mem_fab.dart';
import 'package:mem/features/acts/counter/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mockito/mockito.dart';

import '../helpers.dart';
import '../helpers.mocks.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      'selectedMemIds is empty',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          buildTestAppWithProvider(
            const SelectMemFab(),
          ),
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
        await widgetTester.pumpWidget(
          buildTestAppWithProvider(
            const SelectMemFab(),
            overrides: [
              selectedMemIdsProvider
                  .overrideWith((ref) => ListValueStateNotifier([1])),
            ],
          ),
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
    final mockedActCounterService = MockActCounterClient();
    ActCounterClient.resetWith(mockedActCounterService);

    testWidgets(
      ': tap',
      (widgetTester) async {
        final selectedMemId = randomInt();

        when(mockedActCounterService.createNew(selectedMemId))
            .thenAnswer((realInvocation) => Future.value(null));

        await widgetTester.pumpWidget(
          buildTestAppWithProvider(
            const SelectMemFab(),
            overrides: [
              selectedMemIdsProvider.overrideWith(
                  (ref) => ListValueStateNotifier([selectedMemId])),
            ],
          ),
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
