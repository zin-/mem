import 'package:mem/notifications/notification/action.dart';

class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final List<NotificationAction> actionList;
  final bool usesChronometer;
  final bool ongoing;
  final bool autoCancel;

  NotificationChannel(
    this.id,
    this.name,
    this.description,
    this.actionList, {
    this.usesChronometer = false,
    this.ongoing = false,
    this.autoCancel = true,
  });

  @override
  String toString() => "${super.toString()}: ${{
        "id": id,
        "name": name,
        "description": description,
        "actionList": actionList,
        "usesChronometer": usesChronometer,
        "ongoing": ongoing,
        "autoCancel": autoCancel,
      }}";
}
