import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

AppLocalizations buildL10n([BuildContext? context]) {
  AppLocalizations? tmp;

  if (context != null) tmp = AppLocalizations.of(context);

  return tmp ?? lookupAppLocalizations(const Locale('en'));
}
