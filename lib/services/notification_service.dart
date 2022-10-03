import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/services/mem_service.dart';

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
                'reminder',
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

Future<void> _doneAction(int memId) async {
  // FIXME 一つの関数を呼び出すだけで完結したい
  MemService().save(
    MemDetail(
      (await MemService().fetchMemById(memId))..doneAt = DateTime.now(),
      await MemService().fetchMemItemsByMemId(memId),
    ),
  );
}

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
              await _doneAction(memId);
            }
          }
        }
      },
    );
