import 'package:mem/acts/client.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/act_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

import 'act_counter.dart';
import 'act_counter_repository.dart';

class ActCounterClient {
  final ActsClient _actsClient;
  final MemRepositoryV1 _memRepository;
  final ActRepositoryV2 _actRepository;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(int memId) => v(
        () async => await _actCounterRepository.receive(
          ActCounter(
            await _memRepository.shipById(memId),
            await _actRepository
                .ship(
                  memId: memId,
                  period: ActCounter.period(DateAndTime.now()),
                )
                .then((v) => v.map((e) => e.toV1())),
          ),
        ),
        {
          'memId': memId,
        },
      );

  Future<void> increment(
    int memId,
    DateAndTime when,
  ) =>
      i(
        () async {
          await _actsClient.finish(
            memId,
            when,
          );

          await _actCounterRepository.replace(
            ActCounter(
              await _memRepository.shipById(memId),
              await _actRepository
                  .ship(
                    memId: memId,
                    period: ActCounter.period(when),
                  )
                  .then((v) => v.map((e) => e.toV1())),
            ),
          );
        },
        {
          "memId": memId,
          "when": when,
        },
      );

  ActCounterClient._(
    this._actsClient,
    this._memRepository,
    this._actRepository,
    this._actCounterRepository,
  );

  static ActCounterClient? _instance;

  factory ActCounterClient() => _instance ??= ActCounterClient._(
        ActsClient(),
        MemRepositoryV1(),
        ActRepositoryV2(),
        ActCounterRepository(),
      );

  static resetWith(ActCounterClient? instance) => _instance = instance;
}
