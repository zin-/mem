import 'package:collection/collection.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/notifications/notification/action.dart';

class PauseActNotificationAction extends NotificationAction {
  PauseActNotificationAction(String id, String title)
      : super(
          id,
          title,
          (int memId) async {
            final activeActs = (await ActRepository().shipActive())
                .where((element) => element.memId == memId);

            final now = DateAndTime.now();

            await ActsClient().pause(
              (activeActs.isEmpty
                      ? await ActService().start(memId, now)
                      : activeActs
                          .sorted((a, b) => a.period.compareTo(b.period))
                          .first)
                  .id,
              now,
            );
          },
        );
}
