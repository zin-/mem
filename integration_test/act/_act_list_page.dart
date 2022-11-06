import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/act/gui/act_list_page.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/repositories/log_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  initializeLogger(Level.trace);

  testActListPage();
}

void testActListPage() => group('ActListPage test', () {
      testWidgets(
        ': build',
        (widgetTester) async {
          await runTestPage(widgetTester, const ActListPage());

          expect(find.byType(ActListPage), findsOneWidget);
        },
      );
    });

Future<void> runTestPage(WidgetTester widgetTester, Widget page) async {
  await widgetTester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: (context) => L10n(context).test(),
        home: page,
      ),
    ),
  );
}
