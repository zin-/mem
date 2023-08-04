import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/list_item/view.dart';
import 'package:mem/acts/act_list_states.dart';
import 'package:mem/acts/act_list_view.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/act.dart';

import '../_helpers.dart';

void main() {
  group('Appearance', skip: true, () {
    testWidgets(
      ': fetching',
      (WidgetTester widgetTester) async {
        const memId = 1;

        await runTestWidget(
          widgetTester,
          ProviderScope(
            overrides: [
              actListProvider.overrideWith(
                  (ref, arg) => ListValueStateNotifier<Act>([])),
            ],
            child: const ActListView(memId),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
    );

    group(': fetched', () {
      testWidgets(
        ': empty',
        (WidgetTester widgetTester) async {
          const memId = 2;

          await runTestWidget(
            widgetTester,
            ProviderScope(
              overrides: [
                actListProvider.overrideWith(
                    (ref, arg) => ListValueStateNotifier<Act>([])),
              ],
              child: const ActListView(memId),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
          expect(find.byType(ActListItemView), findsNothing);
        },
      );
    });
  });
}
