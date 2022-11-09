import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/act/gui/act_list_page.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/repositories/log_repository.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  initializeLogger(Level.trace);

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
        },
        tags: TestSize.small,
      );
    });
