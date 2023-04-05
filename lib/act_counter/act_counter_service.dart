import 'package:collection/collection.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_repository_v2.dart';

class ActCounterService {
  final MemRepository _memRepository;
  final ActRepository _actRepository;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(MemId memId) => t(
        {'memId': memId},
        () async {
          await _actCounterRepository.receive(ActCounter(memId));

          await _updateActCounter(memId);
        },
      );

  increment(int memId) => t(
        {'memId': memId},
        () async {
          await _actRepository.receive(Act(
              memId,
              DateAndTimePeriod(
                start: DateAndTime.now(),
                end: DateAndTime.now(),
              )));

          await _updateActCounter(memId);
        },
      );

  Future<void> _updateActCounter(MemId memId) => v(
        {'memId': memId},
        () async {
          final mem = await _memRepository.shipById(memId);

          final now = DateAndTime.now();
          DateAndTime start = DateAndTime(
            now.year,
            now.month,
            now.hour < 5 ? now.day - 1 : now.day,
            5,
            0,
          );
          final acts = await _actRepository.shipByMemId(
            memId,
            period: DateAndTimePeriod(
              start: start,
              end: start.add(const Duration(days: 1)),
            ),
          );

          final lastAct = acts
              .sorted(
                (a, b) => (a.updatedAt ?? a.createdAt!)
                    .compareTo(b.updatedAt ?? b.createdAt!),
              )
              .lastOrNull;

          final actCounter = ActCounter(
            memId,
            name: mem.name,
            actCount: acts.length,
            lastUpdatedAt: lastAct == null
                ? null
                : (lastAct.period.end ?? lastAct.period.start!),
          );

          _actCounterRepository.replace(actCounter);
        },
      );

  ActCounterService._(
    this._memRepository,
    this._actRepository,
    this._actCounterRepository,
  );

  static ActCounterService? _instance;

  factory ActCounterService({
    MemRepository? memRepository,
    ActRepository? actRepository,
    ActCounterRepository? actCounterRepository,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = ActCounterService._(
        memRepository ?? MemRepository(),
        actRepository ?? ActRepository(),
        actCounterRepository ?? ActCounterRepository(),
      );
    }
    return tmp;
  }

  static resetWith(ActCounterService? instance) {
    _instance = instance;
  }
}
