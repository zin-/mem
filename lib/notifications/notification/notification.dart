import 'package:mem/framework/entity.dart';

abstract class Notification extends Entity {
  final int id;

  Notification(this.id);

  @override
  String toString() => {
        'id': id,
      }.toString();
}
