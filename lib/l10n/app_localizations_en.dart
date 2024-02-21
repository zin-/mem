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
  String get search_action => 'Search';

  @override
  String get close_search_action => 'Close';

  @override
  String get filter_action => 'Filter';

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
  String get finish_label => 'Finish';

  @override
  String get pause_act_label => 'Pause';

  @override
  String get start_label => 'Start';

  @override
  String get start_of_day_label => 'Start of day';

  @override
  String get reminder_name => 'Reminder';

  @override
  String get reminder_description => 'To remind at specific time.';

  @override
  String get repeated_reminder_name => 'Repeated Reminder';

  @override
  String get repeated_reminder_description => 'To remind at specific time per day.';

  @override
  String get active_act_notification => 'Active act';

  @override
  String get active_act_notification_description => 'To show active act.';

  @override
  String get paused_act_notification => 'Paused act';

  @override
  String get paused_act_notification_description => 'To start again act.';

  @override
  String get after_act_started_notification => 'After act started';

  @override
  String get after_act_started_notification_description => 'To remind specific amount of time after act started.';

  @override
  String get no_notifications => 'No notifications';

  @override
  String repeated_notification_text(Object notifyAt) {
    return '$notifyAt every day';
  }

  @override
  String repeat_every_n_day_notification_text(Object nDay, Object notifyAt) {
    return '$notifyAt every $nDay days';
  }

  @override
  String get repeat_by_n_day_prefix => 'by';

  @override
  String get repeat_by_n_day_suffix => 'day';

  @override
  String after_act_started_notification_text(Object notifyAt) {
    return '$notifyAt after started';
  }

  @override
  String get edit_notification => 'Edit notification';

  @override
  String get add_notification => 'Add notification';

  @override
  String get dev => 'Under development';

  @override
  String get test => 'Under test';
}
