class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final bool usesChronometer;
  final bool ongoing;

  NotificationChannel(
    this.id,
    this.name,
    this.description, {
    this.usesChronometer = false,
    this.ongoing = false,
  });

  @override
  String toString() => {
        'id': id,
        'name': name,
        'description': description,
        'usesChronometer': usesChronometer,
        'ongoing': ongoing,
      }.toString();
}
