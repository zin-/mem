import 'package:mem/acts/client.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_service.dart';

import 'notification/action.dart';
import 'notification_ids.dart';

Iterable<NotificationAction> buildNotificationActions([
  AppLocalizations? l10n,
]) =>
    v(
      () => [
        NotificationAction(
          doneMemNotificationActionId,
          l10n?.doneLabel ?? 'done',
          (memId) => v(
            () => MemService().doneByMemId(memId),
            {"memId": memId},
          ),
        ),
        NotificationAction(
          startActNotificationActionId,
          l10n?.startLabel ?? 'start',
          (memId) => v(
            () => ActsClient().start(memId, DateAndTime.now()),
            {"memId": memId},
          ),
        ),
        NotificationAction(
          finishActiveActNotificationActionId,
          l10n?.finishLabel ?? 'finish',
          (memId) => v(
            () async => await ActsClient().finish(
              memId,
              DateAndTime.now(),
            ),
            {"memId": memId},
          ),
        ),
        NotificationAction(
          pauseActNotificationActionId,
          l10n?.pauseActLabel ?? 'pause',
          (memId) => v(
            () async => await ActsClient().pause(
              memId,
              DateAndTime.now(),
            ),
            {"memId": memId},
          ),
        )
      ],
      {
        'l10n': l10n,
      },
    );
