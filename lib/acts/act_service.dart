import 'package:collection/collection.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

import 'act_repository.dart';

class ListWithTotalCount<T> {
  final List<T> list;
  final int totalCount;

  ListWithTotalCount(this.list, this.totalCount);
}

class ActService {
  final ActRepository _actRepository;

  Future<ListWithTotalCount<SavedAct>> fetch(
    int? memId,
    int offset,
    int limit,
  ) =>
      v(
        () async {
          final acts = await _actRepository.ship(
            memId: memId,
            actOrderBy: ActOrderBy.descStart,
            offset: offset,
            limit: limit,
          );
          final count = await _actRepository.count(memId: memId);

          return ListWithTotalCount(acts, count);
        },
        {
          "memId": memId,
          "offset": offset,
          "limit": limit,
        },
      );

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

  Future<SavedAct> finish(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          final active = (await _actRepository.shipActiveByMemId(memId))
              .sorted((a, b) => a.createdAt.compareTo(b.createdAt))
              .firstOrNull;

          if (active == null) {
            return await _actRepository.receive(
              Act(
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
        () async => await _actRepository.replace(savedAct),
        {
          "savedAct": savedAct,
        },
      );

  Future<SavedAct> delete(int actId) => i(
        () async => await _actRepository.wasteById(actId),
        {
          "actId": actId,
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
