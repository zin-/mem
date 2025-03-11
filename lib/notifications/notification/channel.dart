import 'package:mem/notifications/notification/action.dart';

class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  final String? groupKey;
  final List<NotificationAction> actionList;
  final bool usesChronometer;
  final bool ongoing;
  final bool autoCancel;
  final bool playSound;
  final bool enableVibration;

  NotificationChannel(
    this.id,
    this.name,
    this.description,
    this.actionList, {
    this.importance = Importance.mid,
    this.groupKey,
    this.usesChronometer = false,
    this.ongoing = false,
    this.autoCancel = true,
    this.playSound = true,
    this.enableVibration = true,
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

enum Importance { mid, high }

