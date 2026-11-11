import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) {
  return widgetTester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => buildL10n(context).test,
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}
