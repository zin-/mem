import 'package:collection/collection.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_query_service.dart';
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
  final ActQueryService _actQueryService;

  Future<ActEntity> start(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActEntity = await _actQueryService
              .fetchLatestAndPausedByMemIds([memId])
              .then(
                (v) => v
                    .groupListsBy(
                      (element) => element.memId,
                    )
                    .values
                    .map(
                      (e) => e.sorted(
                        (a, b) => (b.start ?? b.createdAt)
                            .compareTo(a.start ?? a.createdAt),
                      )[0],
                    )
                    .toList(),
              )
              .then((v) => v.firstOrNull);

          if (latestActEntity == null ||
              latestActEntity.toDomain().state == ActState.finished) {
            return await _actRepository.receiveV2(
              Act.by(memId, startWhen: when),
            );
          } else {
            return await _actRepository.replaceV2(
              latestActEntity.updatedWith(
                latestActEntity.toDomain().start(when),
              ),
            );
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<ActEntity> finish(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActiveActEntity =
              await _actQueryService.fetchLatestByMemIds(memId);

          if (latestActiveActEntity == null ||
              latestActiveActEntity.end != null) {
            return await _actRepository.receiveV2(
              Act.by(memId, endWhen: when),
            );
          } else {
            return await _actRepository.replaceV2(
              latestActiveActEntity.updatedWith(
                latestActiveActEntity.toDomain().finish(when),
              ),
            );
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<Iterable<ActEntity>> pause(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final latestActiveActEntity =
              await _actQueryService.fetchLatestByMemIds(memId);

          return [
            if (latestActiveActEntity != null)
              await _actRepository.replaceV2(
                latestActiveActEntity.updatedWith(
                  latestActiveActEntity.toDomain().finish(when),
                ),
              ),
            await _actRepository.receiveV2(
              Act.by(memId, pausedAt: when),
            ),
          ];
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<ActEntity> edit(ActEntity savedAct) => i(
        () async => await _actRepository.replaceV2(savedAct),
        {
          'savedAct': savedAct,
        },
      );

  ActService._(
    this._actRepository,
    this._actQueryService,
  );

  static ActService? _instance;

  factory ActService() => i(
        () => _instance ??= ActService._(
          ActRepository(),
          ActQueryService(),
        ),
      );
}
