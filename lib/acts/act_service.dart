import 'package:collection/collection.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';

class ListWithTotalCount<T> {
  final List<T> list;
  final int totalCount;

  ListWithTotalCount(this.list, this.totalCount);
}

class ActService {
  final ActRepository _actRepository;

  Future<ListWithTotalCount<SavedActEntity>> fetch(
    int? memId,
    int offset,
    int limit,
  ) =>
      v(
        () async => ListWithTotalCount(
          (await _actRepository
              .ship(
                memId: memId,
                actOrderBy: ActOrderBy.descStart,
                offset: offset,
                limit: limit,
              )
              .then(
                (value) => value.map((e) => e.toV1()).toList(),
              )),
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
        () async => await _actRepository
            .receive(
              ActEntityV2(Act.by(memId, when)),
            )
            .then((v) => v.toV1()),
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
          final active = await _actRepository
              .ship(
                memId: memId,
                isActive: true,
              )
              .then(
                (v) => v
                    .sorted((a, b) => a.createdAt.compareTo(b.createdAt))
                    .firstOrNull,
              );

          if (active == null) {
            return await _actRepository
                .receive(
                  ActEntityV2(Act.by(memId, when, endWhen: when)),
                )
                .then((v) => v.toV1());
          } else {
            return await _actRepository
                .replace(
                  active.copiedWith(
                    end: () => when,
                  ),
                )
                .then((v) => v.toV1());
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<SavedActEntity> edit(SavedActEntity savedAct) => i(
        () async => await _actRepository
            .replace(SavedActEntityV2(savedAct.toMap))
            .then((value) => value.toV1()),
        {
          'savedAct': savedAct,
        },
      );

  Future<SavedActEntity> delete(int actId) => i(
        () async =>
            await _actRepository.waste(id: actId).then((v) => v.single.toV1()),
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
