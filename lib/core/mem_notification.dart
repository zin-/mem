import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class MemNotificationV2 extends Entity {
  // 未保存のMemに紐づくMemNotificationはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotificationV2(this.memId, this.type, this.time, this.message);

  MemNotificationV2 copiedWith(
    int? Function()? time,
    String Function()? message,
  ) =>
      MemNotificationV2(
        memId,
        type,
        time == null ? this.time : time(),
        message == null ? this.message : message(),
      );
}

class SavedMemNotificationV2<I> extends MemNotificationV2
    with SavedDatabaseTupleMixin<I> {
  @override
  int get memId => super.memId as int;

  SavedMemNotificationV2(super.memId, super.type, super.time, super.message);

  @override
  SavedMemNotificationV2<I> copiedWith(
    int? Function()? time,
    String Function()? message,
  ) =>
      SavedMemNotificationV2(
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
