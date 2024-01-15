import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class MemNotification extends Entity {
  // 未保存のMemに紐づくMemNotificationはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotification(this.memId, this.type, this.time, this.message);

  MemNotification copiedWith(
    int? Function()? time,
    String Function()? message,
  ) =>
      MemNotification(
        memId,
        type,
        time == null ? this.time : time(),
        message == null ? this.message : message(),
      );

  @override
  String toString() => "${super.toString()}: ${{
        "memId": memId,
        "type": type,
        "time": time,
        "message": message,
      }}";
}

class SavedMemNotification extends MemNotification
    with SavedDatabaseTupleMixin<int> {
  @override
  int get memId => super.memId as int;

  SavedMemNotification(super.memId, super.type, super.time, super.message);

  @override
  SavedMemNotification copiedWith(
    int? Function()? time,
    String Function()? message,
  ) =>
      SavedMemNotification(
        memId,
        type,
        time == null ? this.time : time(),
        message == null ? this.message : message(),
      )..copiedFrom(this);
}

enum MemNotificationType {
  repeat,
  afterActStarted;

  factory MemNotificationType.fromName(String name) {
    if (name == MemNotificationType.repeat.name) {
      return MemNotificationType.repeat;
    } else if (name == MemNotificationType.afterActStarted.name) {
      return MemNotificationType.afterActStarted;
    }

    throw Exception('Unexpected name: "$name".');
  }
}
