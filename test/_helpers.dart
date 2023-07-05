import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/l10n.dart';

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) =>
    widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: (context) => L10n(context).test(),
        home: widget,
      ),
    );

Future<void> runTestWidgetWithProvider(
  WidgetTester widgetTester,
  Widget widget, {
  List<Override>? overrides,
}) =>
    widgetTester.pumpWidget(
      ProviderScope(
        overrides: overrides ?? [],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          onGenerateTitle: (context) => L10n(context).test(),
          home: widget,
        ),
      ),
    );
