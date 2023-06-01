import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/gui/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) {
  return widgetTester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => L10n(context).test(),
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}