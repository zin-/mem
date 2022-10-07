import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/services/mem_service.dart';

const memReminderChannelId = 'reminder';

class NotificationService {
  final NotificationRepository _notificationRepository;

  Future initialize({Function(int memId)? showMemDetailPage}) => t(
        {},
        () async => await _notificationRepository.initialize(
          notificationActionHandler,
          showMemDetailPage,
        ),
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
                [
                  NotificationActionEntity(_doneActionId, L10n().doneLabel),
                ],
                memReminderChannelId,
                L10n().reminderName,
                L10n().reminderDescription,
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
      {
        'id': notificationId,
        'actionId': actionId,
        'input': input,
        'payload': payload
      },
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
    );
// coverage:ignore-end
