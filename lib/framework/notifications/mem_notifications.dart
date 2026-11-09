import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_notify_at.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/targets/target.dart';

import 'notification_client.dart';
import 'notification/type.dart';
import 'notification_ids.dart';
import 'schedule.dart';

const memIdKey = 'memId';

class MemNotifications {
  static Schedule periodicScheduleOf(
    Mem mem,
    TimeOfDay startOfDay,
    Iterable<MemNotification> memNotifications,
    Act? latestAct,
    DateTime now, {
    Act? scheduleAnchor,
    Target? target,
    int todayCount = 0,
  }) =>
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
            ? CancelSchedule(memRepeatedNotificationId(mem.id!))
            : PeriodicSchedule(
                memRepeatedNotificationId(mem.id!),
                nextRepeatNotifyAt(
                      memNotifications,
                      startOfDay,
                      latestAct,
                      scheduleAnchor ?? mem.resolvedScheduleAnchor,
                      now,
                      target: target,
                      todayCount: todayCount,
                    ) ??
                    now,
                const Duration(days: 1),
                {
                  memIdKey: mem.id,
                  notificationTypeKey: NotificationType.repeat.name,
                },
              ),
        {
          'mem': mem,
          'startOfDay': startOfDay,
          'memNotifications': memNotifications,
          'latestAct': latestAct,
          'now': now,
          'target': target,
          'todayCount': todayCount,
        },
      );

  static DateTime? nextRepeatNotifyAt(
    Iterable<MemNotification> memNotifications,
    TimeOfDay startOfDay,
    Act? latestAct,
    Act? scheduleAnchor,
    DateTime now, {
    Target? target,
    int todayCount = 0,
  }) =>
      v(
        () => MemNotifyAt.repeat(
          memNotifications: memNotifications,
          startOfDay: startOfDay,
          latestAct: latestAct,
          scheduleAnchor: scheduleAnchor,
          now: now,
          target: target,
          todayCount: todayCount,
        )?.at,
        {
          'memNotifications': memNotifications,
          'startOfDay': startOfDay,
          'latestAct': latestAct,
          'scheduleAnchor': scheduleAnchor,
          'now': now,
          'target': target,
          'todayCount': todayCount,
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
