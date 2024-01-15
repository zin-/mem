import 'action.dart';
import 'channel.dart';
import 'notification.dart';

class ShowNotification extends NotificationV1 {
  final String title;
  final String body;
  final String? payloadJson;
  final List<NotificationAction> actions;
  final NotificationChannel channel;

  ShowNotification(
    super.id,
    this.title,
    this.body,
    this.payloadJson,
    this.actions,
    this.channel,
  );

  @override
  String toString() =>
      {
        'title': title,
        'body': body,
        'payloadJson': payloadJson,
        'actions': actions,
        'channel': channel,
      }.toString() +
      super.toString();
}
