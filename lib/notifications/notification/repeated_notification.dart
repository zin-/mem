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

  @override
  String toString() =>
      {
        'notifyFirstAt': notifyFirstAt,
        'interval': interval,
      }.toString() +
      super.toString();
}

enum NotificationInterval { perDay, perWeek, perMonth, perYear }