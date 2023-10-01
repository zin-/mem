import 'package:mem/notifications/notification/finish_active_act_notification_action.dart';

class PauseActNotificationAction extends FinishActiveActNotificationAction {
  PauseActNotificationAction(super.id, super.title);

  @override
  // TODO: implement onTapped
  //  publish PausedActNotification
  // ignore: unnecessary_overrides
  Future<void> Function(int memId) get onTapped => super.onTapped;
}
