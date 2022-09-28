class NotificationRepository {
  static NotificationRepository? _instance;

  NotificationRepository._();

  factory NotificationRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory NotificationRepository.initialize() {
    var tmp = NotificationRepository._();

    _instance = tmp;
    return tmp;
  }

  factory NotificationRepository.withMock(NotificationRepository mock) {
    _instance = mock;
    return mock;
  }
}
