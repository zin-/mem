// coverage:ignore-file
// import 'package:awesome_notifications/awesome_notifications.dart' as an;

import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/notifications/notification/channel.dart';

class AwesomeNotificationsWrapper {
  // late final Future<an.AwesomeNotifications> _awesomeNotificationsFuture =
  //     _initialize(
  //   _androidDefaultIconPath,
  //   _l10n,
  //   _notificationChannels,
  // );

  // Future<an.AwesomeNotifications> _initialize(
  //   String androidDefaultIconPath,
  //   AppLocalizations l10n,
  //   Set<NotificationChannel> notificationChannels,
  // ) =>
  //     v(
  //       () async {
  //         final awesomeNotifications = an.AwesomeNotifications();
  //
  //         await awesomeNotifications.initialize(
  //           'resource://drawable/$androidDefaultIconPath',
  //           notificationChannels
  //               .map(
  //                 (e) => an.NotificationChannel(
  //                   channelKey: e.id,
  //                   channelName: e.name,
  //                   channelDescription: e.description,
  //                 ),
  //               )
  //               .toList(growable: false),
  //           // TODO build variantで変える
  //           debug: true,
  //         );
  //
  //         an.AwesomeNotifications().setListeners(
  //           onActionReceivedMethod: (an.ReceivedAction receivedAction) async {
  //             verbose('onActionReceivedMethod');
  //           },
  //           onNotificationCreatedMethod:
  //               (an.ReceivedNotification receivedNotification) async {
  //             verbose('onNotificationCreatedMethod');
  //           },
  //           onNotificationDisplayedMethod:
  //               (an.ReceivedNotification receivedNotification) async {
  //             verbose('onNotificationDisplayedMethod');
  //           },
  //           onDismissActionReceivedMethod:
  //               (an.ReceivedAction receivedAction) async {
  //             verbose('onDismissActionReceivedMethod');
  //           },
  //         );
  //
  //         return awesomeNotifications;
  //       },
  //     );

  // final String _androidDefaultIconPath;
  // final AppLocalizations _l10n;
  // final Set<NotificationChannel> _notificationChannels;

  AwesomeNotificationsWrapper._(// this._androidDefaultIconPath,
      // this._l10n,
      // this._notificationChannels,
      );

  Future<bool> show(
    int id,
    String channelId,
    String title,
  ) =>
      v(
        () async {
          // return await (await _awesomeNotificationsFuture).createNotification(
          //   content: an.NotificationContent(
          //     id: id,
          //     channelKey: channelId,
          //     title: title,
          //   ),
          // );
          return false;
        },
        {
          'id': id,
          'channelId': channelId,
          'title': title,
        },
      );

  static AwesomeNotificationsWrapper? _instance;

  factory AwesomeNotificationsWrapper(
    String androidDefaultIconPath,
    AppLocalizations l10n,
    Set<NotificationChannel> notificationChannels,
  ) =>
      v(
        () => _instance ??= AwesomeNotificationsWrapper._(
            // androidDefaultIconPath,
            // l10n,
            // notificationChannels,
            ),
        {
          '_instance': _instance,
          'androidDefaultIconPath': androidDefaultIconPath,
          'l10n': l10n,
          'notificationChannels': notificationChannels,
        },
      );

  static void resetSingleton() {
    _instance = null;
  }
}
