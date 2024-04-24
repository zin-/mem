import 'package:mem/acts/act_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/notifications/client.dart';

class ListWithTotalPage<T> {
  final List<T> list;
  final int totalPage;

  ListWithTotalPage(this.list, this.totalPage);
}

class ActsClient {
  final ActService _actService;

  final MemNotificationRepository _memNotificationRepository;

  final NotificationClient _notificationClient;

  Future<ListWithTotalPage<SavedAct>> fetch(
    int? memId,
    int page,
  ) =>
      v(
        () async {
          // TODO settingsから持ってきたい https://github.com/zin-/mem/issues/318
          const limit = 50;
          final offset = (page - 1) * limit;

          final actListWithTotalCount = await _actService.fetch(
            memId,
            offset,
            limit,
          );

          return ListWithTotalPage(
            actListWithTotalCount.list,
            (actListWithTotalCount.totalCount / limit).ceil(),
          );
        },
        {
          "memId": memId,
          "page": page,
        },
      );

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
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final finished = await _actService.finish(memId, when);

          await _notificationClient.pauseActNotification(finished.memId, when);
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> finish(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final finished = await _actService.finish(memId, when);

          _notificationClient.cancelActNotification(finished.memId);

          // ISSUE #226

          return finished;
        },
        {
          "memId": memId,
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
          final savedMemNotifications =
              await _memNotificationRepository.shipByMemId(memId);

          _notificationClient.startActNotifications(
            memId,
            savedMemNotifications,
          );
        },
        {
          "memId": memId,
        },
      );

  ActsClient._(
    this._actService,
    this._memNotificationRepository,
    this._notificationClient,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        ActService(),
        MemNotificationRepository(),
        NotificationClient(),
      );
}
