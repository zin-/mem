import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class L10n {
  final AppLocalizations _appLocalizations;

  String appTitle() => _appLocalizations.appTitle;

  String memListPageTitle() => _appLocalizations.memListPageTitle;

  String memDetailPageTitle() => _appLocalizations.memDetailPageTitle;

  String saveMemSuccessMessage(String memName) =>
      _appLocalizations.saveMemSuccessMessage(memName);

  String memNameIsRequiredWarn() => _appLocalizations.memNameIsRequiredWarn;

  String showNotArchivedLabel() => _appLocalizations.showNotArchivedLabel;

  String showArchivedLabel() => _appLocalizations.showArchivedLabel;

  L10n._(this._appLocalizations);

  static L10n? _instance;

  factory L10n([BuildContext? context]) {
    var tmp = _instance;
    if (tmp == null && context != null) {
      tmp = L10n._(AppLocalizations.of(context));
      _instance = tmp;
    }
    return tmp!;
  }
}
