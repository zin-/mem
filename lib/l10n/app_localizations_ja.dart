import 'app_localizations.dart';

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Mem';

  @override
  String get actChartPageTitle => 'Chart';

  @override
  String get memListDestinationLabel => 'List';

  @override
  String get actListDestinationLabel => 'Acts';

  @override
  String get actCounterConfigureTitle => 'Select target';

  @override
  String get defaultActListPageTitle => 'All';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get memNameLabel => 'Name';

  @override
  String get memMemoLabel => 'Memo';

  @override
  String saveMemSuccessMessage(Object memName) {
    return '\"$memName\"の保存に成功しました。';
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
    return '\"$memName\"の削除取り消しが完了しました。';
  }

  @override
  String get okAction => 'OK';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get searchAction => '検索';

  @override
  String get closeSearchAction => 'やめる';

  @override
  String get filterAction => '絞り込む';

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
  String get finishLabel => '終了';

  @override
  String get pauseActLabel => '一時停止';

  @override
  String get startLabel => '開始';

  @override
  String get startOfDayLabel => '1日の開始時間';

  @override
  String get reminderName => 'Reminder';

  @override
  String get reminderDescription => 'To remind at specific time.';

  @override
  String get repeatedReminderName => '繰り返し通知';

  @override
  String get repeatedReminderDescription => '1日の指定された時間に通知します。';

  @override
  String get activeActNotification => '実施中のAct';

  @override
  String get activeActNotificationDescription => '開始済みのActを表示します。';

  @override
  String get pausedActNotification => '一時停止中のAct';

  @override
  String get pausedActNotificationDescription => '素早く再開するために一時停止中のActを表示します。';

  @override
  String get afterActStartedNotification => 'Act開始後の通知';

  @override
  String get afterActStartedNotificationDescription => 'Act開始の指定時間後に通知します。';

  @override
  String get noNotifications => '通知しない';

  @override
  String repeatedNotificationText(Object notifyAt) {
    return '毎日$notifyAt';
  }

  @override
  String repeatEveryNDayNotificationText(Object nDay, Object notifyAt) {
    return '$nDay日ごとの$notifyAt';
  }

  @override
  String get repeatByNDayPrefix => '';

  @override
  String get repeatByNDaySuffix => '日ごと';

  @override
  String afterActStartedNotificationText(Object notifyAt) {
    return '開始$notifyAt後';
  }

  @override
  String get editNotification => '通知を変更する';

  @override
  String get addNotification => '通知を追加する';

  @override
  String get dev => 'Under development';

  @override
  String get test => 'Under test';
}
