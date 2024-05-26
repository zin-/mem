import 'package:mem/framework/repository/entity.dart';

const _repeatedMessage = "Repeat";
const _repeatByDayOfWeekMessage = "Repeat by day of week";
const _afterActStartedMessage = "Finish?";

class MemNotification extends EntityV1 {
  // 未保存のMemに紐づくMemNotificationはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotification(this.memId, this.type, this.time, this.message);

  bool isEnabled() => time != null;

  bool isRepeated() => type == MemNotificationType.repeat;

  bool isRepeatByNDay() => type == MemNotificationType.repeatByNDay;

  bool isRepeatByDayOfWeek() => type == MemNotificationType.repeatByDayOfWeek;

  bool isAfterActStarted() => type == MemNotificationType.afterActStarted;

  factory MemNotification.repeated(int? memId) => MemNotification(
      memId, MemNotificationType.repeat, null, _repeatedMessage);

  factory MemNotification.repeatByNDay(int? memId) => MemNotification(
      memId, MemNotificationType.repeatByNDay, null, _repeatedMessage);

  factory MemNotification.repeatByDayOfWeek(int? memId, int time) =>
      MemNotification(memId, MemNotificationType.repeatByDayOfWeek, time,
          _repeatByDayOfWeekMessage);

  factory MemNotification.afterActStarted(int? memId) => MemNotification(memId,
      MemNotificationType.afterActStarted, null, _afterActStartedMessage);

  MemNotification copiedWith({
    int Function()? memId,
    int? Function()? time,
    String Function()? message,
  }) =>
      MemNotification(
        memId == null ? this.memId : memId(),
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
  repeatByNDay,
  repeatByDayOfWeek,
  afterActStarted;

  factory MemNotificationType.fromName(String name) =>
      MemNotificationType.values.singleWhere(
        (element) => element.name == name,
        orElse: () => throw Exception('Unexpected name: "$name".'),
      );
}
