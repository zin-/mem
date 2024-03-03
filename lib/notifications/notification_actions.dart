import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'notification/action.dart';
import 'notification/done_mem_notification_action.dart';
import 'notification/finish_active_act_notification_action.dart';
import 'notification/pause_act_notification_action.dart';
import 'notification/start_act_notification_action.dart';

class NotificationActions {
  late final NotificationAction doneMemAction;
  late final NotificationAction startActAction;
  late final NotificationAction finishActiveActAction;
  late final NotificationAction pauseAct;

  NotificationActions(AppLocalizations l10n)
      : doneMemAction = DoneMemNotificationAction('done-mem', l10n.doneLabel),
        startActAction =
            StartActNotificationAction('start-act', l10n.startLabel),
        finishActiveActAction = FinishActiveActNotificationAction(
          'finish-active_act',
          l10n.finishLabel,
        ),
        pauseAct = PauseActNotificationAction('pause-act', l10n.pauseActLabel);

  List<NotificationAction> get list => [
        doneMemAction,
        startActAction,
        finishActiveActAction,
        pauseAct,
      ];
}
