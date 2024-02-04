import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/after_act_started_notification_view.dart';
import 'package:mem/mems/detail/mem_repeated_notification_view.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/repositories/mem_notification.dart';

class NotificationsView extends ConsumerWidget {
  final int? _memId;

  const NotificationsView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _NotificationsView(
          ref.watch(memNotificationsByMemIdProvider(_memId)),
          (current) => (time, message) => ref
                  .read(memNotificationsByMemIdProvider(_memId).notifier)
                  .upsertAll(
                [
                  current.copiedWith(() => time, () => message),
                ],
                (tmp, item) =>
                    tmp.type == item.type &&
                    (tmp is SavedMemNotification && item is SavedMemNotification
                        ? tmp.id == item.id
                        : true),
              ),
        ),
        {"_memId": _memId},
      );
}

class _NotificationsView extends StatelessWidget {
  final List<MemNotification> _notifications;
  final Function(int? pickedTimeOfDay, String message) Function(
      MemNotification current) _onChanged;

  const _NotificationsView(this._notifications, this._onChanged);

  @override
  Widget build(BuildContext context) => v(
        () => Column(
          children: _notifications.map((e) {
            switch (e.type) {
              case MemNotificationType.repeat:
                return MemRepeatedNotificationView(
                  e.time == null
                      ? null
                      : () {
                          final hours = (e.time! / 60 / 60).floor();
                          final minutes =
                              ((e.time! - hours * 60 * 60) / 60).floor();
                          return TimeOfDay(hour: hours, minute: minutes);
                        }(),
                  (pickedTimeOfDay) => _onChanged(e)(
                    pickedTimeOfDay == null
                        ? null
                        : ((pickedTimeOfDay.hour * 60 +
                                pickedTimeOfDay.minute) *
                            60),
                    // pickedTimeOfDay?.convert().toSeconds(),
                    e.message,
                  ),
                );
              case MemNotificationType.afterActStarted:
                return AfterActStartedNotificationView(
                  e.time,
                  e.message,
                  _onChanged(e),
                );
            }
          }).toList(),
        ),
        {"_notifications": _notifications},
      );
}
