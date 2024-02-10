import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';

const keyMemRepeatedNotification = Key("mem-repeated-notification");

class MemRepeatedNotificationView extends ConsumerWidget {
  final int? _memId;

  const MemRepeatedNotificationView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final notification =
              ref.watch(memRepeatedNotificationByMemIdProvider(_memId));

          return ListTile(
            title: TimeOfDayTextFormField(
              timeOfDay: notification.time == null
                  ? null
                  : () {
                      final hours = (notification.time! / 60 / 60).floor();
                      final minutes =
                          ((notification.time! - hours * 60 * 60) / 60).floor();
                      return TimeOfDay(hour: hours, minute: minutes);
                    }(),
              onChanged: (pickedTimeOfDay) => v(
                () {
                  ref
                      .watch(memRepeatedNotificationByMemIdProvider(_memId)
                          .notifier)
                      .updatedBy(notification.copiedWith(
                        time: () => pickedTimeOfDay == null
                            ? null
                            : ((pickedTimeOfDay.hour * 60 +
                                    pickedTimeOfDay.minute) *
                                60),
                        message: () => notification.message,
                      ));
                },
                pickedTimeOfDay,
              ),
            ),
          );
        },
        {"_memId": _memId},
      );
}
