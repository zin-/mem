import 'package:flutter/material.dart';
import 'package:mem/l10n/app_localizations.dart';

AppLocalizations buildL10n([BuildContext? context]) =>
    (context != null ? AppLocalizations.of(context) : null) ??
    lookupAppLocalizations(const Locale('en'));
