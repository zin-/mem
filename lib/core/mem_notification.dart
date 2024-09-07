import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';

const _repeatedMessage = "Repeat";
const _repeatByDayOfWeekMessage = "Repeat by day of week";
const _afterActStartedMessage = "Finish?";

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

class MemNotification {
  // 未保存のMemに紐づくMemNotificationはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotification(this.memId, this.type, this.time, this.message);

  static MemNotification initialByType(
    int? memId,
    MemNotificationType type, {
    int? Function()? time,
  }) {
    switch (type) {
// coverage:ignore-start
      case MemNotificationType.repeat:
        return MemNotification(
            memId, type, time == null ? null : time(), _repeatedMessage);
      case MemNotificationType.repeatByNDay:
        return MemNotification(
            memId, type, time == null ? 1 : time(), _repeatedMessage);
      case MemNotificationType.repeatByDayOfWeek:
        return MemNotification(memId, type, time == null ? null : time(),
            _repeatByDayOfWeekMessage);
      case MemNotificationType.afterActStarted:
        return MemNotification(
            memId, type, time == null ? null : time(), _afterActStartedMessage);
// coverage:ignore-end
    }
  }

  bool isEnabled() => time != null;

  bool isRepeated() => type == MemNotificationType.repeat;

  bool isRepeatByNDay() => type == MemNotificationType.repeatByNDay;

  bool isRepeatByDayOfWeek() => type == MemNotificationType.repeatByDayOfWeek;

  bool isAfterActStarted() => type == MemNotificationType.afterActStarted;

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

            return text.isEmpty ? null : text;
          }
        },
        {
          'memNotifications': memNotifications,
        },
      );

  static String _oneLineRepeat(
    MemNotification repeat,
    MemNotification? repeatByNDay,
    String Function(String at) buildRepeatedNotificationText,
    String Function(String nDay, String at)
        buildRepeatEveryNDayNotificationText,
    String Function(DateAndTime dateAndTime) formatToTimeOfDay,
  ) =>
      v(
        () {
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
        },
        {
          'repeat': repeat,
          'repeatByNDay': repeatByNDay,
        },
      );

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
        {
          'repeatByDayOfWeeks': repeatByDayOfWeeks,
        },
      );

  static String _oneLineAfterAct(
    afterActStarted,
    String Function(String at) buildAfterActStartedNotificationText,
  ) =>
      buildAfterActStartedNotificationText(DateFormat(DateFormat.HOUR24_MINUTE)
          .format(DateAndTime(0, 0, 0, 0, 0, afterActStarted.time)));
}
