import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class L10n {
  static const localizationsDelegates = AppLocalizations.localizationsDelegates;
  static const supportedLocales = AppLocalizations.supportedLocales;

  final AppLocalizations _appLocalizations;

  String appTitle() => _appLocalizations.appTitle;

  String memListPageTitle() => _appLocalizations.memListPageTitle;

  String memDetailPageTitle() => _appLocalizations.memDetailPageTitle;

  String memNameTitle() => _appLocalizations.memNameLabel;

  String memMemoTitle() => _appLocalizations.memMemoLabel;

  String saveMemSuccessMessage(String memName) =>
      _appLocalizations.saveMemSuccessMessage(memName);

  String required() => _appLocalizations.required;

  String requiredError() => _appLocalizations.requiredError;

  String archiveMemSuccessMessage(String memName) =>
      _appLocalizations.archiveMemSuccessMessage(memName);

  String unarchiveMemSuccessMessage(String memName) =>
      _appLocalizations.unarchiveMemSuccessMessage(memName);

  String removeAction() => _appLocalizations.removeAction;

  String removeConfirmation() => _appLocalizations.removeConfirmation;

  String undoAction() => _appLocalizations.undoAction;

  String okAction() => _appLocalizations.okAction;

  String cancelAction() => _appLocalizations.cancelAction;

  String removeMemSuccessMessage(String memName) =>
      _appLocalizations.removeMemSuccessMessage(memName);

  String archiveFilterTitle() => _appLocalizations.archiveFilterTitle;

  String showNotArchivedLabel() => _appLocalizations.showNotArchivedLabel;

  String showArchivedLabel() => _appLocalizations.showArchivedLabel;

  String doneFilterTitle() => _appLocalizations.doneFilterTitle;

  String showNotDoneLabel() => _appLocalizations.showNotDoneLabel;

  String showDoneLabel() => _appLocalizations.showDoneLabel;

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
