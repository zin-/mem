import 'show_notification.dart';

class OneTimeNotification extends ShowNotification {
  final DateTime notifyAt;

  OneTimeNotification(
    super.id,
    super.title,
    super.body,
    super.payloadJson,
    super.actions,
    super.channel,
    this.notifyAt,
  );
}
