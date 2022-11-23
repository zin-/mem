import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/i/gui/act_list_page.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActListPage();
}

void testActListPage() => group('ActListPage test', () {
      testWidgets(
        ': build',
        (widgetTester) async {
          await runTestWidget(
            widgetTester,
            const ProviderScope(
              child: ActListPage(),
            ),
          );

          expect(find.byType(ActListPage), findsOneWidget);

          await widgetTester.pumpAndSettle();
          expect(find.byType(ListView), findsOneWidget);
        },
        tags: TestSize.small,
      );
    });
