import 'package:flutter/material.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

AppLocalizations buildL10n([BuildContext? context]) =>
    (context != null ? AppLocalizations.of(context) : null) ??
    lookupAppLocalizations(const Locale('en'));
