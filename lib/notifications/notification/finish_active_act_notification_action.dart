import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/notifications/notification/action.dart';

class FinishActiveActNotificationAction extends NotificationAction {
  FinishActiveActNotificationAction(String id, String title)
      : super(
          id,
          title,
          (memId) async {
            final acts = (await ActRepository().shipByMemId(memId));

            await ActService().finish(
              acts.isEmpty ? await ActService().startBy(memId) : acts.last,
            );
          },
        );
}
