import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_repository.dart';

import 'act_counter.dart';
import 'act_counter_repository.dart';

class ActCounterClient {
  final ActService _actService;
  final MemRepository _memRepository;
  final ActRepository _actRepository;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(int memId) => v(
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
          await _actService.finish(
            (await _actService.start(memId, now)).id,
            now,
          );

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

  ActCounterClient._(
    this._actService,
    this._memRepository,
    this._actRepository,
    this._actCounterRepository,
  );

  static ActCounterClient? _instance;

  factory ActCounterClient() => _instance ??= ActCounterClient._(
        ActService(),
        MemRepository(),
        ActRepository(),
        ActCounterRepository(),
      );

  static resetWith(ActCounterClient? instance) => _instance = instance;
}
