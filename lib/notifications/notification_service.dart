import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/mem_notifications.dart';
import 'package:mem/mems/mem_service.dart';

import 'notification_repository.dart';

const memReminderChannelId = 'reminder';

class NotificationService {
  final NotificationRepository _notificationRepository;

  Future initialize({Function(int memId)? showMemDetailPage}) => i(
        () async => await _notificationRepository.initialize(
          notificationActionHandler,
          showMemDetailPage,
        ),
      );

  Future<void> memReminder(Mem mem) => i(
        () async {
          // TODO 時間がないときのデフォルト値を設定から取得する
          final memNotifications = MemNotifications(mem, 5, 0);

          for (var element in memNotifications.notifications) {
            await _notificationRepository.receive(element);
          }
        },
        mem,
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

const _doneActionId = 'done';

// FIXME 現時点では、通知に対する操作をテストで実行できない
// coverage:ignore-start
Future<void> notificationActionHandler(
  int notificationId,
  String actionId,
  String? input,
  Map<dynamic, dynamic> payload,
) =>
    v(
      () async {
        if (actionId == _doneActionId) {
          if (payload.containsKey(memIdKey)) {
            final memId = payload[memIdKey];
            if (memId is int) {
              await MemService().doneByMemId(memId);
            }
          }
        }
      },
      {
        'id': notificationId,
        'actionId': actionId,
        'input': input,
        'payload': payload
      },
    );
// coverage:ignore-end
