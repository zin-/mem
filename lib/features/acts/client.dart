import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';

class ListWithTotalPage<T> {
  final List<T> list;
  final int totalPage;

  ListWithTotalPage(this.list, this.totalPage);
}

class ActsClient {
  final ActService _actService;
  final ActRepository _actRepository;
  final ActQueryService _actQueryService;
  final NotificationClient _notificationClient;

  Future<ListWithTotalPage<SavedActEntityV1>> fetch(
    int? memId,
    int page,
  ) =>
      v(
        () async {
          // TODO settingsから持ってきたい https://github.com/zin-/mem/issues/318
          const limit = 50;
          final offset = (page - 1) * limit;

          final actListWithTotalCount = await _actQueryService.fetchPaging(
            memId,
            offset,
            limit,
          );

          return ListWithTotalPage(
            actListWithTotalCount.list
                .map((e) => SavedActEntityV1.fromEntityV2(e))
                .toList(),
            (actListWithTotalCount.totalCount / limit).ceil(),
          );
        },
        {
          "memId": memId,
          "page": page,
        },
      );

  Future<SavedActEntityV1> start(
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

  Future<SavedActEntityV1> edit(
    SavedActEntityV1 savedAct,
  ) =>
      i(
        () async {
          final replaced = await _actService.edit(savedAct);

          if (replaced.value.isActive) {
            _notificationClient.startActNotifications(replaced.value.memId);
          } else {
            _notificationClient.cancelActNotification(replaced.value.memId);
          }

          return replaced;
        },
        {
          "savedAct": savedAct,
        },
      );

  Future<Iterable<SavedActEntityV1>> pause(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final updatedList = await _actService.pause(memId, when);

          await _notificationClient.pauseActNotification(memId);

          return updatedList;
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedActEntityV1> finish(
    int memId,
    DateAndTime when,
  ) =>
      v(
        () async {
          final finished = await _actService.finish(memId, when);

          await _notificationClient.cancelActNotification(finished.value.memId);
          await _notificationClient.setNotificationAfterInactivity();

          // ISSUE #226

          return finished;
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<List<ActEntity>> close(int memId) => v(
        () async {
          final closedActEntities = await _actRepository.wastePausedAct(memId);

          _notificationClient.cancelActNotification(memId);

          return closedActEntities;
        },
        {
          "memId": memId,
        },
      );

  Future<ActEntity> delete(int actId) => i(
        () async {
          final deleted =
              await _actRepository.wasteV2(id: actId).then((v) => v.single);

          _notificationClient.cancelActNotification(deleted.memId!);

          return deleted;
        },
        {
          "actId": actId,
        },
      );

  ActsClient._(
    this._actService,
    this._actRepository,
    this._actQueryService,
    this._notificationClient,
  );

  static ActsClient? _instance;

  factory ActsClient() => _instance ??= ActsClient._(
        ActService(),
        ActRepository(),
        ActQueryService(),
        NotificationClient(),
      );

  static void resetSingleton() => v(
        () {
          NotificationClient.resetSingleton();
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );
}
