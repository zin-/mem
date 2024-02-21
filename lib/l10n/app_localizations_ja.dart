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
  String get search_action => '検索';

  @override
  String get close_search_action => 'やめる';

  @override
  String get filter_action => '絞り込む';

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
  String get done_label => 'Done';

  @override
  String get unarchive_action => 'Unarchive';

  @override
  String get finish_label => '終了';

  @override
  String get pause_act_label => '一時停止';

  @override
  String get start_label => '開始';

  @override
  String get start_of_day_label => '1日の開始時間';

  @override
  String get reminder_name => 'Reminder';

  @override
  String get reminder_description => 'To remind at specific time.';

  @override
  String get repeated_reminder_name => '繰り返し通知';

  @override
  String get repeated_reminder_description => '1日の指定された時間に通知します。';

  @override
  String get active_act_notification => '実施中のAct';

  @override
  String get active_act_notification_description => '開始済みのActを表示します。';

  @override
  String get paused_act_notification => '一時停止中のAct';

  @override
  String get paused_act_notification_description => '素早く再開するために一時停止中のActを表示します。';

  @override
  String get after_act_started_notification => 'Act開始後の通知';

  @override
  String get after_act_started_notification_description => 'Act開始の指定時間後に通知します。';

  @override
  String get no_notifications => '通知しない';

  @override
  String repeated_notification_text(Object notifyAt) {
    return '毎日$notifyAt';
  }

  @override
  String repeat_every_n_day_notification_text(Object nDay, Object notifyAt) {
    return '$nDay日ごとの$notifyAt';
  }

  @override
  String get repeat_by_n_day_prefix => '';

  @override
  String get repeat_by_n_day_suffix => '日ごと';

  @override
  String after_act_started_notification_text(Object notifyAt) {
    return '開始$notifyAt後';
  }

  @override
  String get edit_notification => '通知を変更する';

  @override
  String get add_notification => '通知を追加する';

  @override
  String get dev => 'Under development';

  @override
  String get test => 'Under test';
}
