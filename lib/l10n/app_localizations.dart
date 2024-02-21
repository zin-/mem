import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mem'**
  String get appTitle;

  /// No description provided for @actChartPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Act chart'**
  String get actChartPageTitle;

  /// No description provided for @memListDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get memListDestinationLabel;

  /// No description provided for @actListDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Acts'**
  String get actListDestinationLabel;

  /// No description provided for @actCounterConfigureTitle.
  ///
  /// In en, this message translates to:
  /// **'Select target'**
  String get actCounterConfigureTitle;

  /// No description provided for @defaultActListPageTitle.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get defaultActListPageTitle;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @memNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get memNameLabel;

  /// No description provided for @memMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get memMemoLabel;

  /// No description provided for @saveMemSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Save success. {memName}'**
  String saveMemSuccessMessage(Object memName);

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Error: required'**
  String get requiredError;

  /// No description provided for @archiveMemSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Archive success. {memName}'**
  String archiveMemSuccessMessage(Object memName);

  /// No description provided for @unarchiveMemSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Unarchive success. {memName}'**
  String unarchiveMemSuccessMessage(Object memName);

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @removeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Can I remove this?'**
  String get removeConfirmation;

  /// No description provided for @removeMemSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove success. {memName}'**
  String removeMemSuccessMessage(Object memName);

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @undoMemSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Undo success. {memName}'**
  String undoMemSuccessMessage(Object memName);

  /// No description provided for @okAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @search_action.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_action;

  /// No description provided for @close_search_action.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_search_action;

  /// No description provided for @filter_action.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter_action;

  /// No description provided for @archiveFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveFilterTitle;

  /// No description provided for @showNotArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Show not archived'**
  String get showNotArchivedLabel;

  /// No description provided for @showArchivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchivedLabel;

  /// No description provided for @doneFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneFilterTitle;

  /// No description provided for @showNotDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Show not done'**
  String get showNotDoneLabel;

  /// No description provided for @showDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Show done'**
  String get showDoneLabel;

  /// No description provided for @done_label.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done_label;

  /// No description provided for @unarchive_action.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive_action;

  /// No description provided for @finish_label.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish_label;

  /// No description provided for @pause_act_label.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_act_label;

  /// No description provided for @start_label.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_label;

  /// No description provided for @start_of_day_label.
  ///
  /// In en, this message translates to:
  /// **'Start of day'**
  String get start_of_day_label;

  /// No description provided for @reminder_name.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder_name;

  /// No description provided for @reminder_description.
  ///
  /// In en, this message translates to:
  /// **'To remind at specific time.'**
  String get reminder_description;

  /// No description provided for @repeated_reminder_name.
  ///
  /// In en, this message translates to:
  /// **'Repeated Reminder'**
  String get repeated_reminder_name;

  /// No description provided for @repeated_reminder_description.
  ///
  /// In en, this message translates to:
  /// **'To remind at specific time per day.'**
  String get repeated_reminder_description;

  /// No description provided for @active_act_notification.
  ///
  /// In en, this message translates to:
  /// **'Active act'**
  String get active_act_notification;

  /// No description provided for @active_act_notification_description.
  ///
  /// In en, this message translates to:
  /// **'To show active act.'**
  String get active_act_notification_description;

  /// No description provided for @paused_act_notification.
  ///
  /// In en, this message translates to:
  /// **'Paused act'**
  String get paused_act_notification;

  /// No description provided for @paused_act_notification_description.
  ///
  /// In en, this message translates to:
  /// **'To start again act.'**
  String get paused_act_notification_description;

  /// No description provided for @after_act_started_notification.
  ///
  /// In en, this message translates to:
  /// **'After act started'**
  String get after_act_started_notification;

  /// No description provided for @after_act_started_notification_description.
  ///
  /// In en, this message translates to:
  /// **'To remind specific amount of time after act started.'**
  String get after_act_started_notification_description;

  /// No description provided for @no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get no_notifications;

  /// No description provided for @repeated_notification_text.
  ///
  /// In en, this message translates to:
  /// **'{notifyAt} every day'**
  String repeated_notification_text(Object notifyAt);

  /// No description provided for @repeat_every_n_day_notification_text.
  ///
  /// In en, this message translates to:
  /// **'{notifyAt} every {nDay} days'**
  String repeat_every_n_day_notification_text(Object nDay, Object notifyAt);

  /// No description provided for @repeat_by_n_day_prefix.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get repeat_by_n_day_prefix;

  /// No description provided for @repeat_by_n_day_suffix.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get repeat_by_n_day_suffix;

  /// No description provided for @after_act_started_notification_text.
  ///
  /// In en, this message translates to:
  /// **'{notifyAt} after started'**
  String after_act_started_notification_text(Object notifyAt);

  /// No description provided for @edit_notification.
  ///
  /// In en, this message translates to:
  /// **'Edit notification'**
  String get edit_notification;

  /// No description provided for @add_notification.
  ///
  /// In en, this message translates to:
  /// **'Add notification'**
  String get add_notification;

  /// No description provided for @dev.
  ///
  /// In en, this message translates to:
  /// **'Under development'**
  String get dev;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Under test'**
  String get test;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
