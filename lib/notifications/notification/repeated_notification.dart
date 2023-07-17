import 'show_notification.dart';

class RepeatedNotification extends ShowNotification {
  final DateTime notifyFirstAt;
  final NotificationInterval interval;

  RepeatedNotification(
    super.id,
    super.title,
    super.body,
    super.payloadJson,
    super.actions,
    super.channel,
    this.notifyFirstAt,
    this.interval,
  );
}

enum NotificationInterval { perDay, perWeek, perMonth, perYear }
