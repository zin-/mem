import 'package:collection/collection.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/act_repository.dart';

import 'act_repository.dart';

class ListWithTotalCount<T> {
  final List<T> list;
  final int totalCount;

  ListWithTotalCount(this.list, this.totalCount);
}

class ActService {
  final ActRepositoryV2 _actRepository;
  final ActRepository _actRepositoryV1;

  Future<ListWithTotalCount<SavedAct>> fetch(
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
          ))
              .map((e) => e.toV1())
              .toList(),
          await _actRepository.count(memId: memId),
        ),
        {
          'memId': memId,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<SavedAct> start(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async => await _actRepositoryV1.receive(
          Act(memId, DateAndTimePeriod(start: when)),
        ),
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> finish(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final active = (await _actRepositoryV1.shipActiveByMemId(memId))
              .sorted((a, b) => a.createdAt.compareTo(b.createdAt))
              .firstOrNull;

          if (active == null) {
            return await _actRepositoryV1.receive(
              Act(
                memId,
                DateAndTimePeriod(
                  start: when,
                  end: when,
                ),
              ),
            );
          } else {
            return await _actRepositoryV1.replace(
              active.copiedWith(
                () => active.period.copiedWith(when),
              ),
            );
          }
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  Future<SavedAct> edit(SavedAct savedAct) => i(
        () async => await _actRepositoryV1.replace(savedAct),
        {
          "savedAct": savedAct,
        },
      );

  Future<SavedAct> delete(int actId) => i(
        () async => await _actRepositoryV1.wasteById(actId),
        {
          "actId": actId,
        },
      );

  ActService._(
    this._actRepository,
    this._actRepositoryV1,
  );

  static ActService? _instance;

  factory ActService() => i(
        () => _instance ??= ActService._(
          ActRepositoryV2(),
          ActRepository(),
        ),
      );
}
