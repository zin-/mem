import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';

class TestSize {
  static const small = 'Small';

  TestSize._();
}

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) =>
    widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: (context) => L10n(context).test(),
        home: widget,
      ),
    );
