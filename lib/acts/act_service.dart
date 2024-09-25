import 'package:collection/collection.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
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
          (await _actRepository.ship(
            memId: memId,
            actOrderBy: ActOrderBy.descStart,
            offset: offset,
            limit: limit,
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
        () async => await _actRepository.receive(
          ActEntity(memId, DateAndTimePeriod(start: when)),
        ),
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
          final active = (await _actRepository.ship(
            memId: memId,
            isActive: true,
          ))
              .sorted((a, b) => a.createdAt.compareTo(b.createdAt))
              .firstOrNull;

          if (active == null) {
            return await _actRepository.receive(
              ActEntity(
                memId,
                DateAndTimePeriod(
                  start: when,
                  end: when,
                ),
              ),
            );
          } else {
            return await _actRepository.replace(
              active.copiedWith(
                period: () => active.period.copiedWith(when),
              ),
            );
          }
        },
        {
          'memId': memId,
          'when': when,
        },
      );

  Future<SavedActEntity> edit(SavedActEntity savedAct) => i(
        () async => await _actRepository.replace(savedAct),
        {
          'savedAct': savedAct,
        },
      );

  Future<SavedActEntity> delete(int actId) => i(
        () async => (await _actRepository.waste(id: actId)).single,
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
