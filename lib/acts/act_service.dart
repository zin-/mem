import 'package:collection/collection.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

import 'act_repository.dart';

class ListWithTotalPage<T> {
  final List<T> list;
  final int totalPage;

  ListWithTotalPage(this.list, this.totalPage);
}

class ActService {
  final ActRepository _actRepository;

  Future<ListWithTotalPage<SavedAct>> fetch(
    int? memId,
    // FIXME pageはFEの概念なのでServiceに定義されているのはおかしい
    int page,
  ) =>
      v(
        () async {
          const limit = 50;
          final offset = (page - 1) * limit;

          final acts = await _actRepository.ship(
            memId: memId,
            actOrderBy: ActOrderBy.descStart,
            offset: offset,
            limit: limit,
          );
          final count = await _actRepository.count(memId: memId);

          return ListWithTotalPage(acts, (count / limit).ceil());
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
