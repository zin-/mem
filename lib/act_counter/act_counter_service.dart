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
        () async => await _actCounterRepository.receive(
          ActCounter(
            await _memRepository.shipById(memId),
            await _actRepository.shipByMemId(
              memId,
              period: ActCounter.period(DateAndTime.now()),
            ),
          ),
        ),
      );

  Future<void> increment(int memId) => t(
        {'memId': memId},
        () async {
          await _actRepository.receive(
            Act(
              memId,
              DateAndTimePeriod(
                start: DateAndTime.now(),
                end: DateAndTime.now(),
              ),
            ),
          );

          await _actCounterRepository.replace(
            ActCounter(
              await _memRepository.shipById(memId),
              await _actRepository.shipByMemId(
                memId,
                period: ActCounter.period(DateAndTime.now()),
              ),
            ),
          );
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
