import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';

import 'client.dart';
import 'notification/type.dart';
import 'notification_ids.dart';
import 'schedule.dart';

const memIdKey = 'memId';

class MemNotifications {
  static Iterable<Schedule> scheduleOf(
    SavedMem savedMem,
    TimeOfDay startOfDay,
    Iterable<SavedMemNotification>? memNotifications,
    Function callback,
  ) =>
      v(
        () {
          Iterable<Schedule>? memPeriodicSchedule;
          if (memNotifications != null) {
            memPeriodicSchedule = _memPeriodicSchedule(
              savedMem.id,
              memNotifications.whereType<SavedMemNotification>(),
              callback,
            );
          }

          return [
            _memPeriodSchedules(
              savedMem,
              startOfDay,
              callback,
            ),
            if (memPeriodicSchedule != null) memPeriodicSchedule,
          ].flattened;
        },
        {
          "savedMem": savedMem,
          "startOfDay": startOfDay,
          "memNotifications": memNotifications,
        },
      );

  static Iterable<Schedule> _memPeriodSchedules(
    SavedMem savedMem,
    TimeOfDay startOfDay,
    Function callback,
  ) =>
      v(
        () {
          final periodStart = savedMem.period?.start;
          final Schedule periodStartSchedule = periodStart == null
              ? CancelSchedule(memStartNotificationId(savedMem.id))
              : TimedSchedule(
                  memStartNotificationId(savedMem.id),
                  periodStart.isAllDay
                      ? DateTime(
                          periodStart.year,
                          periodStart.month,
                          periodStart.day,
                          startOfDay.hour,
                          startOfDay.minute,
                        )
                      : periodStart,
                  callback,
                  {
                    memIdKey: savedMem.id,
                    notificationTypeKey: NotificationType.startMem.name,
                  },
                );

          final periodEnd = savedMem.period?.end;
          final Schedule periodEndSchedule = periodEnd == null
              ? CancelSchedule(memEndNotificationId(savedMem.id))
              : () {
                  final endOfDay = startOfDay.subtractMinutes(1);
                  return TimedSchedule(
                    memEndNotificationId(savedMem.id),
                    periodEnd.isAllDay
                        ? DateTime(
                            periodEnd.year,
                            periodEnd.month,
                            // FIXME とりあえずここで実装するが、DateAndTimeの仕様として取り込むべきかも
                            //  endOfDayがstartOfDayより大きければ問題はない
                            //  小さい場合、それは1日回っているので、登録する日も追加する必要がある
                            startOfDay.compareTo(endOfDay) > 0
                                ? periodEnd.day + 1
                                : periodEnd.day,
                            endOfDay.hour,
                            endOfDay.minute,
                          )
                        : periodEnd,
                    callback,
                    {
                      memIdKey: savedMem.id,
                      notificationTypeKey: NotificationType.endMem.name,
                    },
                  );
                }();

          return [
            periodStartSchedule,
            periodEndSchedule,
          ];
        },
        {
          "savedMem": savedMem,
          "startOfDay": startOfDay,
        },
      );

  static Iterable<Schedule> _memPeriodicSchedule(
    int memId,
    Iterable<SavedMemNotification> savedMemNotifications,
    Function callback,
  ) =>
      v(
        () {
          final enables =
              savedMemNotifications.where((element) => element.isEnabled());

          if (enables.where((element) => element.isRepeated()).isEmpty) {
            return [
              CancelSchedule(memRepeatedNotificationId(memId)),
            ];
          } else {
            final repeat =
                enables.singleWhere((element) => element.isRepeated());
            final repeatNDay = enables
                .singleWhereOrNull((element) => element.isRepeatByNDay());

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final notifyFirstAt = DateTime.fromMicrosecondsSinceEpoch(
              today.microsecondsSinceEpoch + (repeat.time ?? 0) * 1000 * 1000,
            );

            return [
              PeriodicSchedule(
                memRepeatedNotificationId(memId),
                notifyFirstAt,
                Duration(
                  days: repeatNDay?.time ?? 1,
                ),
                callback,
                {
                  memIdKey: memId,
                  notificationTypeKey: NotificationType.repeat.name,
                },
              )
            ];
          }
        },
        {
          "memId": memId,
          "savedMemNotifications": savedMemNotifications,
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

// FIXME どこからでも参照できるとこに定義する
//  どこからでもか？
//    フロントでしか使えない
extension on TimeOfDay {
  TimeOfDay subtractMinutes(int minutes) {
    int subtracted = (_totalMinutes - minutes + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: subtracted ~/ 60, minute: subtracted % 60);
  }

  int compareTo(TimeOfDay other) =>
      _totalMinutes.compareTo(other._totalMinutes);

  int get _totalMinutes => hour * 60 + minute;
}
