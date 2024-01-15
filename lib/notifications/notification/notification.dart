import 'package:mem/framework/repository/entity.dart';

abstract class NotificationV1 extends EntityV1 {
  final int id;

  NotificationV1(this.id);

  @override
  String toString() => {
        'id': id,
      }.toString();
}
