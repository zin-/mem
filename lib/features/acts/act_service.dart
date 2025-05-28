import 'package:collection/collection.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_repository.dart';

class ListWithTotalCount<T> {
  final List<T> list;
  final int totalCount;

  ListWithTotalCount(this.list, this.totalCount);
}

class ActService {
  final ActRepository _actRepository;

  Future fetchLatestByMemIds(
    Iterable<int>? memIdsIn,
  ) =>
      v(
        () async {
          final r = [
            ...await ActRepository().ship(
              memIdsIn: memIdsIn,
              latestByMemIds: true,
            ),
            ...await ActRepository().ship(
              memIdsIn: memIdsIn,
              paused: true,
            ),
          ]
              .groupListsBy(
                (element) => element.value.memId,
              )
              .values
              .map(
                (e) => e.sorted(
                  (a, b) => (b.value.period?.start ?? b.createdAt)
                      .compareTo(a.value.period?.start ?? a.createdAt),
                )[0],
              );
          return r;
        },
        {
          'memIdsIn': memIdsIn,
        },
      );

  Future<ListWithTotalCount<SavedActEntity>> fetch(
    int? memId,
    int offset,
    int limit,
  ) =>
      v(
        () async => ListWithTotalCount(
          await _actRepository.ship(
            memId: memId,
            actOrderBy: ActOrderBy.descStart,
            offset: offset,
            limit: limit,
          ),
          await _actRepository.count(memId: memId),
        ),
        {
          'memId': memId,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<SavedActEntity> start(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActEntity = await _actRepository
              .ship(
                memId: memId,
                actOrderBy: ActOrderBy.descStart,
                limit: 1,
              )
              .then((v) => v.singleOrNull);

          if (latestActEntity == null || latestActEntity.value is FinishedAct) {
            return await _actRepository.receive(
              ActEntity(Act.by(memId, startWhen: when)),
            );
          } else {
            return await _actRepository.replace(
              latestActEntity.updatedWith(
                (v) => v.start(when),
              ),
            );
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<SavedActEntity> finish(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActiveActEntity = await _actRepository
              .ship(
                memId: memId,
                actOrderBy: ActOrderBy.descStart,
                limit: 1,
              )
              .then((v) => v.singleOrNull);

          if (latestActiveActEntity == null ||
              latestActiveActEntity.value is FinishedAct) {
            return await _actRepository.receive(
              ActEntity(Act.by(memId, endWhen: when)),
            );
          } else {
            return await _actRepository.replace(
              latestActiveActEntity.updatedWith(
                (v) => v.finish(when),
              ),
            );
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<Iterable<SavedActEntity>> pause(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActiveActEntity = await _actRepository
              .ship(
                memId: memId,
                actOrderBy: ActOrderBy.descStart,
                limit: 1,
              )
              .then((v) => v.singleOrNull);

          return [
            if (latestActiveActEntity != null)
              await _actRepository.replace(
                latestActiveActEntity.updatedWith(
                  (v) => v.finish(when),
                ),
              ),
            await _actRepository.receive(
              ActEntity(Act.by(memId, pausedAt: when)),
            ),
          ];
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<SavedActEntity?> close(int memId) => i(
        () async {
          final latestPausedActEntity = await _actRepository
              .ship(
                memId: memId,
                paused: true,
                actOrderBy: ActOrderBy.descStart,
                limit: 1,
              )
              .then((v) => v.singleOrNull);

          if (latestPausedActEntity == null) {
            return null;
          }

          return await _actRepository
              .waste(id: latestPausedActEntity.id)
              .then((v) => v.single);
        },
        {
          'memId': memId,
        },
      );

  Future<SavedActEntity> edit(SavedActEntity savedAct) => i(
        () async => await _actRepository.replace(savedAct),
        {
          'savedAct': savedAct,
        },
      );

  Future<SavedActEntity> delete(int actId) => i(
        () async => await _actRepository.waste(id: actId).then((v) => v.single),
        {
          'actId': actId,
        },
      );

  ActService._(
    this._actRepository,
  );

  static ActService? _instance;

  factory ActService() => i(
        () => _instance ??= ActService._(
          ActRepository(),
        ),
      );
}
