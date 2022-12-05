import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act_list_item_view.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/acts/act_list_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/gui/list_value_state_notifier.dart';

import '../_helpers.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      ': fetching',
      (WidgetTester widgetTester) async {
        const memId = 1;

        await runTestWidget(
          widgetTester,
          ProviderScope(
            overrides: [
              actListProvider.overrideWithProvider((argument) =>
                  StateNotifierProvider((ref) => ListValueStateNotifier(null))),
            ],
            child: const ActListView(memId),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
      tags: TestSize.small,
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
                actListProvider.overrideWithProvider((argument) =>
                    StateNotifierProvider(
                        (ref) => ListValueStateNotifier(List.empty()))),
              ],
              child: const ActListView(memId),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
          expect(find.byType(ActListItemView), findsNothing);
        },
        tags: TestSize.small,
      );
      testWidgets(
        ': 2 acts',
        (WidgetTester widgetTester) async {
          const memId = 3;

          await runTestWidget(
            widgetTester,
            ProviderScope(
              overrides: [
                actListProvider.overrideWithProvider((argument) =>
                    StateNotifierProvider((ref) => ListValueStateNotifier(
                          List.generate(
                            2,
                            (index) => Act(memId, DateAndTimePeriod.startNow()),
                          ),
                        ))),
              ],
              child: const ActListView(memId),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byType(ListView), findsOneWidget);
          expect(find.byType(ActListItemView), findsNWidgets(2));
        },
        tags: TestSize.small,
      );
    });
  });
}
