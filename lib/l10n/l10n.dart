import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

// gen-l10n の delegates は Flutter SDK の Material / Cupertino を指す。
// material_ui のウィジェットはこちらの delegate がないと ja を読めない。
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

AppLocalizations buildL10n([BuildContext? context]) =>
    (context != null ? AppLocalizations.of(context) : null) ??
    lookupAppLocalizations(const Locale('en'));
