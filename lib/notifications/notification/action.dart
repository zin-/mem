import 'package:mem/framework/repository/entity.dart';

class NotificationAction extends EntityV1 {
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
