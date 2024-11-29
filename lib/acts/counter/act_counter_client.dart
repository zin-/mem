import 'package:mem/acts/counter/act_counter_entity.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/mems/mem_repository.dart';

import 'act_counter.dart';
import 'act_counter_repository.dart';

class ActCounterClient {
  final ActsClient _actsClient;
  final MemRepositoryV2 _memRepository;
  final ActRepository _actRepository;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(int memId) => v(
        () async {
          await _actCounterRepository.receive(
            ActCounterEntity.from(
              await _memRepository.ship(id: memId).then((v) => v.single.toV1()),
              await _actRepository.ship(
                memId: memId,
                period: ActCounter.period(DateAndTime.now()),
              ),
            ),
          );
        },
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
            ActCounterEntity.from(
              await _memRepository.ship(id: memId).then((v) => v.single.toV1()),
              await _actRepository.ship(
                memId: memId,
                period: ActCounter.period(when),
              ),
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
        MemRepositoryV2(),
        ActRepository(),
        ActCounterRepository(),
      );

  static resetWith(ActCounterClient? instance) => _instance = instance;
}
