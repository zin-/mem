import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/counter/act_counter_entity.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mems/mem_repository.dart';

import 'act_counter.dart';
import 'act_counter_repository.dart';

class ActCounterClient {
  final ActsClient _actsClient;
  final MemRepository _memRepository;
  final ActQueryService _actQueryService;
  final ActCounterRepository _actCounterRepository;

  Future<void> createNew(int memId) => v(
        () async {
          await _actCounterRepository.receive(
            ActCounterEntity.from(
              (await _memRepository
                  .ship(id: memId)
                  .then((v) => v.singleOrNull?.value))!,
              await _actQueryService
                  .fetchByMemIdAndPeriod(
                    memId,
                    ActCounter.period(DateAndTime.now()),
                  )
                  .then((v) =>
                      v.map((e) => SavedActEntityV1.fromEntityV2(e)).toList()),
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
              (await _memRepository
                  .ship(id: memId)
                  .then((v) => v.singleOrNull?.value))!,
              await _actQueryService
                  .fetchByMemIdAndPeriod(
                    memId,
                    ActCounter.period(when),
                  )
                  .then((v) =>
                      v.map((e) => SavedActEntityV1.fromEntityV2(e)).toList()),
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
    this._actQueryService,
    this._actCounterRepository,
  );

  static ActCounterClient? _instance;

  factory ActCounterClient() => _instance ??= ActCounterClient._(
        ActsClient(),
        MemRepository(),
        ActQueryService(),
        ActCounterRepository(),
      );

  static resetWith(ActCounterClient? instance) => _instance = instance;
}
