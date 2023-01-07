import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/mems/mem_service.dart';

import 'notification_repository.dart';

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
          final notifyAtV2 = mem.notifyAtV2;
          DateTime? notifyAt;
          if (notifyAtV2 != null && notifyAtV2.isAllDay == true) {
            // TODO 時間がないときのデフォルト値を設定から取得する
            notifyAt = DateTime(
              notifyAtV2.year,
              notifyAtV2.month,
              notifyAtV2.day,
              5,
              0,
            );
          } else {
            notifyAt = mem.notifyAtV2;
          }

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
