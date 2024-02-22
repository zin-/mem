import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mem';

  @override
  String get actChartPageTitle => 'Act chart';

  @override
  String get memListDestinationLabel => 'List';

  @override
  String get actListDestinationLabel => 'Acts';

  @override
  String get actCounterConfigureTitle => 'Select target';

  @override
  String get defaultActListPageTitle => 'All';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get memNameLabel => 'Name';

  @override
  String get memMemoLabel => 'Memo';

  @override
  String saveMemSuccessMessage(Object memName) {
    return 'Save success. $memName';
  }

  @override
  String get requiredError => 'Error: required';

  @override
  String archiveMemSuccessMessage(Object memName) {
    return 'Archive success. $memName';
  }

  @override
  String unarchiveMemSuccessMessage(Object memName) {
    return 'Unarchive success. $memName';
  }

  @override
  String get removeAction => 'Remove';

  @override
  String get removeConfirmation => 'Can I remove this?';

  @override
  String removeMemSuccessMessage(Object memName) {
    return 'Remove success. $memName';
  }

  @override
  String get undoAction => 'Undo';

  @override
  String undoMemSuccessMessage(Object memName) {
    return 'Undo success. $memName';
  }

  @override
  String get okAction => 'OK';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get searchAction => 'Search';

  @override
  String get closeSearchAction => 'Close';

  @override
  String get filterAction => 'Filter';

  @override
  String get archiveFilterTitle => 'Archive';

  @override
  String get showNotArchivedLabel => 'Show not archived';

  @override
  String get showArchivedLabel => 'Show archived';

  @override
  String get doneFilterTitle => 'Done';

  @override
  String get showNotDoneLabel => 'Show not done';

  @override
  String get showDoneLabel => 'Show done';

  @override
  String get doneLabel => 'Done';

  @override
  String get unarchiveAction => 'Unarchive';

  @override
  String get finishLabel => 'Finish';

  @override
  String get pauseActLabel => 'Pause';

  @override
  String get startLabel => 'Start';

  @override
  String get startOfDayLabel => 'Start of day';

  @override
  String get reminderName => 'Reminder';

  @override
  String get reminderDescription => 'To remind at specific time.';

  @override
  String get repeatedReminderName => 'Repeated Reminder';

  @override
  String get repeatedReminderDescription => 'To remind at specific time per day.';

  @override
  String get activeActNotification => 'Active act';

  @override
  String get activeActNotificationDescription => 'To show active act.';

  @override
  String get pausedActNotification => 'Paused act';

  @override
  String get pausedActNotificationDescription => 'To start again act.';

  @override
  String get afterActStartedNotification => 'After act started';

  @override
  String get afterActStartedNotificationDescription => 'To remind specific amount of time after act started.';

  @override
  String get noNotifications => 'No notifications';

  @override
  String repeatedNotificationText(Object notifyAt) {
    return '$notifyAt every day';
  }

  @override
  String repeatEveryNDayNotificationText(Object nDay, Object notifyAt) {
    return '$notifyAt every $nDay days';
  }

  @override
  String get repeatByNDayPrefix => 'by';

  @override
  String get repeatByNDaySuffix => 'day';

  @override
  String afterActStartedNotificationText(Object notifyAt) {
    return '$notifyAt after started';
  }

  @override
  String get editNotification => 'Edit notification';

  @override
  String get addNotification => 'Add notification';

  @override
  String get dev => 'Under development';

  @override
  String get test => 'Under test';
}
