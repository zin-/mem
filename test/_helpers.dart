import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';

class TestSize {
  static const small = 'Small';

  TestSize._();
}

Future<void> runWidget(WidgetTester widgetTester, Widget widget) => v(
      {'widgetTester': widgetTester, 'widget': widget},
      () => widgetTester.pumpWidget(MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: widget,
      )),
    );
