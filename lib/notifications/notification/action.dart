import 'package:mem/framework/entity.dart';

class NotificationAction extends EntityV3 {
  final String id;
  final String title;
  final Future<void> Function(int memId) onTapped;

  NotificationAction(this.id, this.title, this.onTapped);

  @override
  String toString() => {
        'id': id,
        'title': title,
      }.toString();
}
