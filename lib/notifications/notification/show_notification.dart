import 'channel.dart';
import 'notification.dart';

class ShowNotification extends Notification {
  final String title;
  final String body;
  final String? payloadJson;
  final NotificationChannel channel;

  ShowNotification(
    super.id,
    this.title,
    this.body,
    this.payloadJson,
    this.channel,
  );

  @override
  String toString() =>
      super.toString() +
      {
        "title": title,
        "body": body,
        "payloadJson": payloadJson,
        "channel": channel,
      }.toString();
}
