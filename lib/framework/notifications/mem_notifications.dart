import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';

import 'notification_client.dart';
import 'notification/type.dart';
import 'notification_ids.dart';
import 'schedule.dart';

const memIdKey = 'memId';

class MemNotifications {
  static Schedule periodicScheduleOf(
    SavedMemEntityV2 savedMemEntity,
    TimeOfDay startOfDay,
    Iterable<MemNotification> memNotifications,
    Act? latestAct,
    DateTime now,
  ) =>
      v(
        () => memNotifications
                .where(
                  (e) =>
                      e.isEnabled() &&
                      (e.isRepeated() ||
                          e.isRepeatByNDay() ||
                          e.isRepeatByDayOfWeek()),
                )
                .isEmpty
            ? CancelSchedule(memRepeatedNotificationId(savedMemEntity.id))
            : PeriodicSchedule(
                memRepeatedNotificationId(savedMemEntity.id),
                nextRepeatNotifyAt(
                      memNotifications,
                      startOfDay,
                      latestAct,
                      now,
                    ) ??
                    now,
                const Duration(days: 1),
                {
                  memIdKey: savedMemEntity.id,
                  notificationTypeKey: NotificationType.repeat.name,
                },
              ),
        {
          'savedMemEntity': savedMemEntity,
          'startOfDay': startOfDay,
          'memNotifications': memNotifications,
          'latestAct': latestAct,
          'now': now,
        },
      );

  static DateTime? nextRepeatNotifyAt(
    Iterable<MemNotification> memNotifications,
    TimeOfDay startOfDay,
    Act? latestAct,
    DateTime now,
  ) =>
      v(
        () {
          DateTime? notifyAt;

          if (latestAct?.isActive == true) {
            return null;
          } else if (memNotifications
              .where((e) => !e.isAfterActStarted())
              .isNotEmpty) {
            final repeatAt = memNotifications
                .singleWhereOrNull((e) => e.isRepeated() && e.isEnabled())
                ?.time;
            final timeOfDay = repeatAt == null
                ? startOfDay
                : TimeOfDay(hour: 0, minute: (repeatAt / 60).floor());

            if (latestAct == null) {
              notifyAt = now.copyWith(
                  hour: timeOfDay.hour,
                  minute: timeOfDay.minute,
                  second: 0,
                  millisecond: 0,
                  microsecond: 0);
            } else {
              notifyAt = (latestAct.period?.end ?? now)
                  .copyWith(
                      hour: timeOfDay.hour,
                      minute: timeOfDay.minute,
                      second: 0,
                      millisecond: 0,
                      microsecond: 0)
                  .add(Duration(
                    days: memNotifications
                            .singleWhereOrNull((e) => e.isRepeatByNDay())
                            ?.time ??
                        1,
                  ));
            }

            while (notifyAt != null && now.compareTo(notifyAt) > 0) {
              notifyAt = notifyAt.add(const Duration(days: 1));
            }

            final daysOfWeeks = memNotifications
                .where((e) => e.isRepeatByDayOfWeek() && e.isEnabled());

            while (daysOfWeeks.isNotEmpty &&
                !daysOfWeeks.map((e) => e.time).contains(notifyAt?.weekday)) {
              notifyAt = notifyAt?.add(const Duration(days: 1));
            }
          }

          return notifyAt;
        },
        {
          'memNotifications': memNotifications,
          'startOfDay': startOfDay,
          'latestAct': latestAct,
          'now': now,
        },
      );
}

class AllMemNotificationsId {
  static List<int> of(int memId) => [
        memStartNotificationId(memId),
        memEndNotificationId(memId),
        memRepeatedNotificationId(memId),
        activeActNotificationId(memId),
        pausedActNotificationId(memId),
        afterActStartedNotificationId(memId),
      ];
}
