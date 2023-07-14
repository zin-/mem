class NotificationChannel {
  final String id;
  final String name;
  final String description;

  NotificationChannel(this.id, this.name, this.description);

  @override
  String toString() => {
        'id': id,
        'name': name,
        'description': description,
      }.toString();
}
