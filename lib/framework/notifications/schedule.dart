import 'package:mem/framework/repository/entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';

abstract class Schedule with Entity {
  final int id;

  Schedule(this.id);

  factory Schedule.of(
    int? memId,
    DateTime? at,
    NotificationType notificationType,
  ) =>
      v(
        () => at == null
            ? CancelSchedule(
                notificationType.buildNotificationId(memId),
              )
            : TimedSchedule(
                notificationType.buildNotificationId(memId),
                at,
                {
                  if (memId != null) memIdKey: memId,
                  notificationTypeKey: notificationType.name,
                },
              ),
        {
          'memId': memId,
          'at': at,
          'notificationType': notificationType,
        },
      );

  @override
  Map<String, dynamic> get toMap => {
        'id': id,
      };

  @override
  Entity updatedWith(Function(dynamic v) update) {
    // TODO: implement updatedWith
    throw UnimplementedError();
  }
}

class CancelSchedule extends Schedule {
  CancelSchedule(super.id);
}

class TimedSchedule extends Schedule {
  final DateTime startAt;
  final Map<String, dynamic> params;

  TimedSchedule(
    super.id,
    this.startAt,
    this.params,
  );

  @override
  Map<String, dynamic> get toMap => super.toMap
    ..addAll({
      'startAt': startAt,
      'params': params,
    });
}

class PeriodicSchedule extends TimedSchedule {
  final Duration duration;

  PeriodicSchedule(
    super.id,
    super.startAt,
    this.duration,
    super.params,
  );

  @override
  Map<String, dynamic> get toMap => super.toMap
    ..addAll({
      'duration': duration,
    });
}
