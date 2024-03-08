import 'package:mem/acts/act_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/notifications/client.dart';

class ActsClient {
  final ActService _actService;

  final MemRepository _memRepository;
  final MemNotificationRepository _memNotificationRepository;

  final NotificationClient _notificationClient;

  Future<SavedAct> start(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final startedAct = await _actService.start(memId, when);

          _registerStartNotifications(memId);

          return startedAct;
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> edit(
    SavedAct savedAct,
  ) =>
      i(
        () async {
          final replaced = await _actService.edit(savedAct);

          if (replaced.period.end == null) {
            _registerStartNotifications(replaced.memId);
          } else {
            _notificationClient.cancelActNotification(replaced.memId);
          }

          return replaced;
        },
        {
          "savedAct": savedAct,
        },
      );

  Future pause(
    int actId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final finished = await _actService.finish(actId, when);

          final mem = await _memRepository.shipById(finished.memId);
          await _notificationClient.pauseActNotification(
              mem.id, mem.name, when);
        },
        {
          "actId": actId,
          "when": when,
        },
      );

  Future<SavedAct> finish(
    int actId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final finished = await _actService.finish(actId, when);

          _notificationClient.cancelActNotification(finished.memId);

          // ISSUE #226

          return finished;
        },
        {
          "actId": actId,
          "when": when,
        },
      );

  Future<SavedAct> delete(int actId) => i(
        () async {
          final deleted = await _actService.delete(actId);

          _notificationClient.cancelActNotification(deleted.memId);

          return deleted;
        },
        {
          "actId": actId,
        },
      );

  void _registerStartNotifications(int memId) => v(
        () async {
          final memName = (await _memRepository.shipById(memId)).name;
          final savedMemNotifications =
              await _memNotificationRepository.shipByMemId(memId);

          _notificationClient.startActNotifications(
            memId,
            memName,
            savedMemNotifications,
          );
        },
        {
          "memId": memId,
        },
      );

  ActsClient._(
    this._actService,
    this._memRepository,
    this._memNotificationRepository,
    this._notificationClient,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        ActService(),
        MemRepository(),
        MemNotificationRepository(),
        NotificationClient(),
      );
}
