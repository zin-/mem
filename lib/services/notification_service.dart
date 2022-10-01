import 'package:mem/logger.dart';
import 'package:mem/repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository notificationRepository;

  Future initialize({Function(int memId)? showMemDetailPage}) => t(
        {},
        () async => await notificationRepository.initialize(showMemDetailPage),
      );

  NotificationService._(this.notificationRepository);

  static NotificationService? _instance;

  factory NotificationService({
    NotificationRepository? notificationRepository,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = NotificationService._(
        notificationRepository ?? NotificationRepository(),
      );
      _instance = tmp;
    }
    return tmp;
  }
}
