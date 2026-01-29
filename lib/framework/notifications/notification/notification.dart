import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/key_with_value.dart';
import 'package:mem/framework/notifications/notification/channel.dart';

class Notification
    with
        EntityV1<Map<String, dynamic>>,
        KeyWithValue<int, Map<String, dynamic>> {
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
  ) {
    key = id;
    value = {
      'title': title,
      'body': body,
      'channel': channel,
      'payload': payload,
    };
  }

  @override
  EntityV1<Map<String, dynamic>> updatedWith(
      Map<String, dynamic> Function(Map<String, dynamic> v) update) {
    // TODO: implement updatedWith
    throw UnimplementedError();
  }
}
