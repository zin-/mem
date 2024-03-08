import 'package:mem/framework/repository/entity.dart';

abstract class Notification extends EntityV1 {
  final int id;

  Notification(this.id);

  @override
  String toString() => "${super.toString()}: ${{
        "id": id,
      }}";
}
