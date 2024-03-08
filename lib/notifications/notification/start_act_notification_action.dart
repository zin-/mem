import 'package:mem/acts/client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification/action.dart';

const startActNotificationActionId = "start-act";

class StartActNotificationAction extends NotificationAction {
  StartActNotificationAction(String title)
      : super(
          startActNotificationActionId,
          title,
          (memId) => v(
            () => ActsClient().start(memId, DateAndTime.now()),
            {
              "memId": memId,
            },
          ),
        );
}
