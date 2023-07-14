import 'one_time_notification.dart';

class RepeatedNotification extends OneTimeNotification {
  final NotificationInterval interval;

  RepeatedNotification(
    super.id,
    super.title,
    super.body,
    super.notifyAt,
    super.payloadJson,
    super.actions,
    this.interval,
    super.channel,
  );
}

enum NotificationInterval { perDay, perWeek, perMonth, perYear }
