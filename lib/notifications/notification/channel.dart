class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final bool usesChronometer;
  final bool ongoing;
  final bool autoCancel;

  NotificationChannel(
    this.id,
    this.name,
    this.description, {
    this.usesChronometer = false,
    this.ongoing = false,
    this.autoCancel = true,
  });

  @override
  String toString() => {
        'id': id,
        'name': name,
        'description': description,
        'usesChronometer': usesChronometer,
        'ongoing': ongoing,
        'autoCancel': autoCancel,
      }.toString();
}
