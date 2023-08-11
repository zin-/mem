import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_repository_v2.dart';

import 'act_counter.dart';
import 'act_counter_repository.dart';

class ActCounterService {
  final ActService _actService;
  final MemRepository _memRepository;
  final ActRepository _actRepository;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(MemId memId) => i(
        () async => await _actCounterRepository.receive(
          ActCounter(
            await _memRepository.shipById(memId),
            await _actRepository.shipByMemId(
              memId,
              period: ActCounter.period(DateAndTime.now()),
            ),
          ),
        ),
        {'memId': memId},
      );

  Future<void> increment(int memId, DateAndTime now) => i(
        () async {
          await _actService.finish(await _actService.startV2(
            Act(memId, DateAndTimePeriod(start: now)),
          ));

          await _actCounterRepository.replace(
            ActCounter(
              await _memRepository.shipById(memId),
              await _actRepository.shipByMemId(
                memId,
                period: ActCounter.period(now),
              ),
            ),
          );
        },
        {'memId': memId},
      );

  ActCounterService._(
    this._actService,
    this._memRepository,
    this._actRepository,
    this._actCounterRepository,
  );

  static ActCounterService? _instance;

  factory ActCounterService() => _instance ??= ActCounterService._(
        ActService(),
        MemRepository(),
        ActRepository(),
        ActCounterRepository(),
      );

  static resetWith(ActCounterService? instance) => _instance = instance;
}
