import 'package:mem/framework/entity_v3.dart';

class NotificationAction extends EntityV3 {
  final String id;
  final String title;

  NotificationAction(this.id, this.title);

  @override
  String toString() => {
        'id': id,
        'title': title,
      }.toString();
}
