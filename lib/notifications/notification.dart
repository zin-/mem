import 'package:mem/framework/entity_v3.dart';
import 'package:mem/notifications/notification_channel.dart';

abstract class Notification extends EntityV3 {
  final int id;

  Notification(this.id);
}

class OneTimeNotification extends Notification {
  final String title;
  final String body;
  final DateTime notifyAt;
  final String payloadJson;
  final List<NotificationAction> actions;
  final NotificationChannel channel;

  OneTimeNotification(
    super.id,
    this.title,
    this.body,
    this.notifyAt,
    this.payloadJson,
    this.actions,
    this.channel,
  );
}

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

class CancelNotification extends Notification {
  CancelNotification(super.id);
}

class NotificationAction extends EntityV3 {
  final String id;
  final String title;

  NotificationAction(this.id, this.title);
}
