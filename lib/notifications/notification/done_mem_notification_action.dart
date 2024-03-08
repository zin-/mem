import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/notification/action.dart';

const doneMemNotificationActionId = "done-mem";

class DoneMemNotificationAction extends NotificationAction {
  DoneMemNotificationAction(String title)
      : super(
          doneMemNotificationActionId,
          title,
          (memId) => MemService().doneByMemId(memId),
        );
}
