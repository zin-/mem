import 'channel.dart';
import 'notification.dart';

class ShowNotification extends Notification {
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final NotificationChannel channel;

  ShowNotification(
    super.id,
    this.title,
    this.body,
    this.payload,
    this.channel,
  );

  @override
  String toString() =>
      super.toString() +
      {
        "title": title,
        "body": body,
        "payload": payload,
        "channel": channel,
      }.toString();
}
