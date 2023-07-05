import 'dart:convert';

import 'package:mem/components/l10n.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/notifications/notification.dart';

const _memIdKey = 'memId';
const _doneActionId = 'done';
const _startNotificationBody = 'start';
const _endNotificationBody = 'end';

class MemNotifications {
  final List<Notification> notifications;

  int _startNotificationId(int memId) => memId * 10 + 1;

  int _endNotificationId(int memId) => memId * 10 + 2;

  MemNotifications(
    Mem mem,
    int startHourOfDay,
    int startMinuteOfDay,
  ) : notifications = List.empty(growable: true) {
    if (mem.isDone() || mem.isArchived()) {
      notifications.add(CancelNotification(_startNotificationId(mem.id)));
      notifications.add(CancelNotification(_endNotificationId(mem.id)));
    } else {
      final now = DateTime.now();

      final periodStart = mem.period?.start;
      if (periodStart != null && periodStart.isAfter(now)) {
        notifications.add(_createNotificationAt(
          _startNotificationId(mem.id),
          mem.name,
          _startNotificationBody,
          periodStart,
          mem.id,
          startHourOfDay,
          startMinuteOfDay,
        ));
      }

      final periodEnd = mem.period?.end;
      if (periodEnd != null && periodEnd.isAfter(now)) {
        notifications.add(_createNotificationAt(
          _endNotificationId(mem.id),
          mem.name,
          _endNotificationBody,
          periodEnd,
          mem.id,
          startHourOfDay,
          startMinuteOfDay,
        ));
      }
    }
  }

  Notification _createNotificationAt(
    id,
    title,
    body,
    DateAndTime notifyAt,
    int memId,
    startHourOfDay,
    startMinuteOfDay,
  ) {
    return OneTimeNotification(
      id,
      title,
      body,
      notifyAt.isAllDay == true
          ? DateTime(
              notifyAt.year,
              notifyAt.month,
              notifyAt.day,
              startHourOfDay,
              startMinuteOfDay,
            )
          : notifyAt,
      json.encode({_memIdKey: memId}),
      [
        NotificationAction(_doneActionId, L10n().doneLabel),
      ],
      'reminder',
      L10n().reminderName,
      L10n().reminderDescription,
    );
  }
}
