import 'channel.dart';
import 'notification.dart';
import 'action.dart';

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
