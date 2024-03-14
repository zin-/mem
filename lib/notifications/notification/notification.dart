import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/notifications/notification/channel.dart';

class Notification extends KeyWithValue<int, Map<String, dynamic>> {
  final String title;
  final String body;
  final NotificationChannel channel;
  final Map<String, dynamic> payload;

  Notification(
    int id,
    this.title,
    this.body,
    this.channel,
    this.payload,
  ) : super(
          id,
          {
            "title": title,
            "body": body,
            "channel": channel,
            "payload": payload,
          },
        );

  @override
  String toString() => "${super.toString()}: ${{
        "key": key,
        "value": value,
      }}";
}
