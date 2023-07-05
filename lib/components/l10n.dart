import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

BuildContext? _context;

AppLocalizations buildL10n([BuildContext? context]) {
  if (context == null) {
    if (_context == null) {
      return lookupAppLocalizations(const Locale('en'));
    } else {
      return AppLocalizations.of(_context!) ??
          lookupAppLocalizations(const Locale('en'));
    }
  } else {
    _context ??= context;

    return AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
  }
}

// TODO arbに追加するたびに関数を増やさなくても良いようにする
class L10n {
  final AppLocalizations _appLocalizations;

  L10n._(this._appLocalizations);

  String appTitle() => _appLocalizations.appTitle;

  String memListPageTitle() => _appLocalizations.memListPageTitle;

  String memDetailPageTitle() => _appLocalizations.memDetailPageTitle;

  String actCounterConfigureTitle() =>
      _appLocalizations.actCounterConfigureTitle;

  String memNameTitle() => _appLocalizations.memNameLabel;

  String memMemoTitle() => _appLocalizations.memMemoLabel;

  String saveMemSuccessMessage(String memName) =>
      _appLocalizations.saveMemSuccessMessage(memName);

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

  late String doneLabel = _appLocalizations.done_label;

  // Notification
  late String reminderName = _appLocalizations.reminder_name;
  late String reminderDescription = _appLocalizations.reminder_description;

  String test() => _appLocalizations.test;

  static const localizationsDelegates = AppLocalizations.localizationsDelegates;
  static const supportedLocales = AppLocalizations.supportedLocales;

  static L10n? _instance;

  factory L10n([BuildContext? context]) {
    var tmp = _instance;
    if (tmp == null && context != null) {
      final appLocalizations = AppLocalizations.of(context);
      if (appLocalizations != null) {
        tmp = L10n._(appLocalizations);
        _instance = tmp;
      }
    }
    return tmp!;
  }
}
