import 'package:mem/acts/act_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/notifications/notification/action.dart';

class StartActNotificationAction extends NotificationAction {
  StartActNotificationAction(String id, String title)
      : super(
          id,
          title,
          (memId) => ActService().startV2(
            Act(memId, DateAndTimePeriod.startNow()),
          ),
        );
}
