import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/notification_repository.dart';

import 'act_repository.dart';

class ActService {
  final ActRepository _actRepository;
  final NotificationRepository _notificationRepository;

  Future<SavedAct> start(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async => await _actRepository.receive(
          Act(memId, DateAndTimePeriod(start: when)),
        ),
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> finish(int actId, DateAndTime when) => i(
        () async {
          final finishingAct = await _actRepository.shipById(actId);

          final replaced = await _actRepository.replace(
            finishingAct.copiedWith(
              () => finishingAct.period.copiedWith(when),
            ),
          );

          _cancelNotifications(replaced.memId);

          // ISSUE #226

          return replaced;
        },
        [actId, when],
      );

  Future<SavedAct> edit(SavedAct editingAct) => i(
        () async => await _actRepository.replace(editingAct),
        editingAct,
      );

  Future<SavedAct> delete(int id) => i(
        () async {
          final wasted = await _actRepository.wasteById(id);

          _cancelNotifications(wasted.memId);

          return wasted;
        },
        id,
      );

  Future _cancelNotifications(int memId) => v(
        () async {
          await _notificationRepository.discard(activeActNotificationId(memId));
          await _notificationRepository
              .discard(afterActStartedNotificationId(memId));
        },
        memId,
      );

  ActService._(
    this._actRepository,
    this._notificationRepository,
  );

  static ActService? _instance;

  factory ActService() => i(
        () => _instance ??= ActService._(
          ActRepository(),
          NotificationRepository(),
        ),
      );
}
