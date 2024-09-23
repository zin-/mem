import 'package:mem/acts/act_service.dart';
import 'package:mem/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/acts/act_entity.dart';

class ListWithTotalPage<T> {
  final List<T> list;
  final int totalPage;

  ListWithTotalPage(this.list, this.totalPage);
}

class ActsClient {
  final ActService _actService;

  final NotificationClient _notificationClient;

  Future<ListWithTotalPage<SavedActEntity>> fetch(
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

  Future<SavedActEntity> start(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final startedAct = await _actService.start(memId, when);

          _notificationClient.startActNotifications(memId);

          return startedAct;
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedActEntity> edit(
    SavedActEntity savedAct,
  ) =>
      i(
        () async {
          final replaced = await _actService.edit(savedAct);

          if (replaced.isActive) {
            _notificationClient.startActNotifications(replaced.memId);
          } else {
            _notificationClient.cancelActNotification(replaced.memId);
          }

          return replaced;
        },
        {
          "savedAct": savedAct,
        },
      );

  Future<void> pause(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final finished = await _actService.finish(memId, when);

          await _notificationClient.pauseActNotification(finished.memId);
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedActEntity> finish(
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

  Future<SavedActEntity> delete(int actId) => i(
        () async {
          final deleted = await _actService.delete(actId);

          _notificationClient.cancelActNotification(deleted.memId);

          return deleted;
        },
        {
          "actId": actId,
        },
      );

  ActsClient._(
    this._actService,
    this._notificationClient,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        ActService(),
        NotificationClient(),
      );
}
