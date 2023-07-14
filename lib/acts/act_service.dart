import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/channels.dart';
import 'package:mem/notifications/notification/show_notification.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_repository.dart';

class ActService {
  final MemRepository _memRepository;
  final ActRepository _actRepository;
  final NotificationRepository _notificationRepository;

  Future<Act> startBy(int memId) => i(
        () async {
          final received = await _actRepository.receive(
            Act(
              memId,
              DateAndTimePeriod.startNow(),
            ),
          );

          await _notificationRepository.receive(
            ShowNotification(
              activeActNotificationId(memId),
              (await _memRepository.shipById(memId)).name,
              // TODO l10n
              'body',
              // TODO mem詳細を表示する
              'payloadJson',
              [
                // TODO finishAct
              ],
              activeActNotificationChannel,
              // TODO 音はない方がいい
            ),
          );

          return received;
        },
        memId,
      );

  Future<Act> finish(Act act) => i(
        () async {
          final finished = await _actRepository.replace(
            Act(
              act.memId,
              DateAndTimePeriod(
                start: act.period.start,
                end: DateAndTime.now(),
              ),
              id: act.id,
            ),
          );

          await _notificationRepository
              .discard(activeActNotificationId(act.memId));

          return finished;
        },
        act,
      );

  ActService._(
    this._memRepository,
    this._actRepository,
    this._notificationRepository,
  );

  static ActService? _instance;

  factory ActService() => _instance ??= _instance = ActService._(
        MemRepository(),
        ActRepository(),
        NotificationRepository(),
      );
}
