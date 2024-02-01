import 'package:mem/framework/repository/entity.dart';

const _repeatedMessage = "Repeat";
const _afterActStartedMessage = "Finish?";

class MemNotification extends EntityV1 {
  // 未保存のMemに紐づくMemNotificationはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotification(this.memId, this.type, this.time, this.message);

  factory MemNotification.repeated(int? memId) => MemNotification(
      memId, MemNotificationType.repeat, null, _repeatedMessage);

  factory MemNotification.afterActStarted(int? memId) => MemNotification(memId,
      MemNotificationType.afterActStarted, null, _afterActStartedMessage);

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
