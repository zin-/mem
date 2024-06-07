import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/logger/log_service.dart';

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

  static String? toOneLine(
    Iterable<MemNotification> memNotifications,
    String Function(String at) buildRepeatedNotificationText,
    String Function(String nDay, String at)
        buildRepeatEveryNDayNotificationText,
    String Function(String at) buildAfterActStartedNotificationText,
    String Function(DateAndTime dateAndTime) formatToTimeOfDay,
  ) =>
      v(
        () {
          final enables =
              memNotifications.where((element) => element.isEnabled());

          if (enables.isEmpty) {
            return null;
          } else {
            final repeat =
                enables.singleWhereOrNull((element) => element.isRepeated());
            final repeatByNDay = enables
                .singleWhereOrNull((element) => element.isRepeatByNDay());
            final repeatByDayOfWeeks =
                enables.where((element) => element.isRepeatByDayOfWeek());
            final afterActStarted = enables
                .singleWhereOrNull((element) => element.isAfterActStarted());

            final text = [
              if (repeat != null)
                _oneLineRepeat(
                  repeat,
                  repeatByNDay,
                  buildRepeatedNotificationText,
                  buildRepeatEveryNDayNotificationText,
                  formatToTimeOfDay,
                ),
              if (repeatByDayOfWeeks.isNotEmpty)
                _oneLineRepeatByDaysOfWeek(repeatByDayOfWeeks),
              if (afterActStarted != null)
                _oneLineAfterAct(
                  afterActStarted,
                  buildAfterActStartedNotificationText,
                ),
            ].join(", ");

            return text;
          }
        },
        {'memNotifications': memNotifications},
      );

  static String _oneLineRepeat(
    MemNotification repeat,
    MemNotification? repeatByNDay,
    String Function(String at) buildRepeatedNotificationText,
    String Function(String nDay, String at)
        buildRepeatEveryNDayNotificationText,
    String Function(DateAndTime dateAndTime) formatToTimeOfDay,
  ) {
    if (repeatByNDay != null && (repeatByNDay.time ?? 0) > 1) {
      return buildRepeatEveryNDayNotificationText(
        repeatByNDay.time.toString(),
        formatToTimeOfDay(
          DateAndTime(0, 0, 0, 0, 0, repeat.time),
        ),
      );
    } else {
      return buildRepeatedNotificationText(formatToTimeOfDay(
        DateAndTime(0, 0, 0, 0, 0, repeat.time),
      ));
    }
  }

  static String _oneLineRepeatByDaysOfWeek(
    Iterable<MemNotification> repeatByDayOfWeeks,
  ) =>
      v(
        () {
          final dateFormat = DateFormat.E();
          final firstSunday = DateTime(0, 1, 2);

          return repeatByDayOfWeeks
              .map((e) => firstSunday.add(Duration(days: e.time!)))
              .sorted((a, b) => a.compareTo(b))
              .map((e) => dateFormat.format(e))
              .join(", ");
        },
        {'repeatByDayOfWeeks': repeatByDayOfWeeks},
      );

  static String _oneLineAfterAct(
    afterActStarted,
    String Function(String at) buildAfterActStartedNotificationText,
  ) =>
      buildAfterActStartedNotificationText(DateFormat(DateFormat.HOUR24_MINUTE)
          .format(DateAndTime(0, 0, 0, 0, 0, afterActStarted.time)));
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
