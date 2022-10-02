import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository _notificationRepository;

  Future initialize({Function(int memId)? showMemDetailPage}) => t(
        {},
        () async => await _notificationRepository.initialize(showMemDetailPage),
      );

  memReminder(Mem mem) => t(
        {'mem': mem},
        () {
          final notifyAt = mem.notifyOn?.add(Duration(
            // TODO 時間がないときのデフォルト値を設定から取得する
            hours: mem.notifyAt?.hour ?? 5,
            minutes: mem.notifyAt?.minute ?? 0,
          ));

          if (mem.isArchived() || mem.isDone()) {
            _notificationRepository.discard(mem.id);
          } else {
            if (notifyAt != null && notifyAt.isAfter(DateTime.now())) {
              _notificationRepository.receive(
                mem.id,
                mem.name,
                notifyAt,
              );
            }
          }
        },
      );

  NotificationService._(this._notificationRepository);

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
