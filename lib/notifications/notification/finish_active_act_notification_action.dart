import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/notifications/notification/action.dart';

class FinishActiveActNotificationAction extends NotificationAction {
  FinishActiveActNotificationAction(String id, String title)
      : super(
          id,
          title,
          (memId) async {
            final acts = (await ActRepository().shipByMemId(memId));

            await ActService().finish(
              acts.isEmpty
                  ? await ActService().start(memId, DateAndTime.now())
                  : acts.last,
            );
          },
        );
}
