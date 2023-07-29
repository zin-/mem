import 'package:mem/mems/mem_service.dart';
import 'package:mem/notifications/notification/action.dart';

class DoneMemNotificationAction extends NotificationAction {
  DoneMemNotificationAction(String id, String title)
      : super(
          id,
          title,
          (memId) => MemService().doneByMemId(memId),
        );
}
