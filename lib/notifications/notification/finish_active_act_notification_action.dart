import 'package:collection/collection.dart';
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
            final activeActs = (await ActRepository().shipActive())
                .where((element) => element.memId == memId);

            final now = DateAndTime.now();
            ActService().finishV2(
              (activeActs.isEmpty
                      ? await ActService().start(memId, now)
                      : activeActs
                          .sorted((a, b) => a.period.compareTo(b.period))
                          .first)
                  .id!,
              now,
            );
          },
        );
}
