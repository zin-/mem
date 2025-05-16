class NotificationAction {
  final String id;
  final String title;
  final Future<void> Function(int memId) onTapped;

  NotificationAction(
    this.id,
    this.title,
    this.onTapped,
  );

  @override
  String toString() => "${super.toString()}: ${{
        "id": id,
        "title": title,
      }}";
}
