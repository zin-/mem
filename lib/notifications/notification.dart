import 'package:mem/frame_work/entity_v3.dart';

abstract class Notification extends EntityV3 {
  final int id;

  Notification(this.id);

  @override
  String toString() => {'id': id}.toString();
}

class OneTimeNotification extends Notification {
  final String title;
  final String body;
  final DateTime notifyAt;
  final String payloadJson;
  final List<NotificationAction> actions;
  final String channelId;
  final String channelName;
  final String channelDescription;

  OneTimeNotification(
    super.id,
    this.title,
    this.body,
    this.notifyAt,
    this.payloadJson,
    this.actions,
    this.channelId,
    this.channelName,
    this.channelDescription,
  );
}

class CancelNotification extends Notification {
  CancelNotification(super.id);
}

class NotificationAction extends EntityV3 {
  final String id;
  final String title;

  NotificationAction(this.id, this.title);
}
