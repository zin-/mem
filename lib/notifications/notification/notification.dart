import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/notifications/notification/channel.dart';

class NotificationV2 with Entity, KeyWithValue<int, Map<String, dynamic>> {
  final String title;
  final String body;
  final NotificationChannel channel;
  final Map<String, dynamic> payload;

  NotificationV2(
    int id,
    this.title,
    this.body,
    this.channel,
    this.payload,
  ) {
    key = id;
    value = {
      'title': title,
      'body': body,
      'channel': channel,
      'payload': payload,
    };
  }
}
