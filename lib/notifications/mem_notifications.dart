import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification_entity.dart';

import 'notification_client.dart';
import 'notification/type.dart';
import 'notification_ids.dart';
import 'schedule.dart';

const memIdKey = 'memId';

class MemNotifications {
  static Schedule periodicScheduleOf(
    SavedMemV1 savedMem,
    TimeOfDay startOfDay,
    Iterable<SavedMemNotificationEntity> memNotifications,
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
            ? CancelSchedule(memRepeatedNotificationId(savedMem.id))
            : PeriodicSchedule(
                memRepeatedNotificationId(savedMem.id),
                nextRepeatNotifyAt(
                      memNotifications,
                      startOfDay,
                      latestAct,
                      now,
                    ) ??
                    now,
                const Duration(days: 1),
                {
                  memIdKey: savedMem.id,
                  notificationTypeKey: NotificationType.repeat.name,
                },
              ),
        {
          'savedMem': savedMem,
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
              .whereType<SavedMemNotificationEntity>()
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
              notifyAt = latestAct.period.end!
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
