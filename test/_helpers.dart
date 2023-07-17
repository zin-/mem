import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/l10n.dart';

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) =>
    widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => buildL10n(context).test,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) => buildL10n(context).test,
          home: widget,
        ),
      ),
    );
