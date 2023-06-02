import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service_v2.dart';

final actRepository = ActRepository();

Future<List<Act>> fetchByMemIdIs(MemId memId) =>
    actRepository.shipByMemId(memId);

Future<Act> start(MemId memId) => actRepository.receive(
      Act(
        memId,
        DateAndTimePeriod.startNow(),
      ),
    );

Future<Act> finish(Act act) => actRepository.replace(
      Act(
        act.memId,
        DateAndTimePeriod(
          start: act.period.start,
          end: DateAndTime.now(),
        ),
        id: act.id,
      ),
    );

Future<Act> save(Act act) => v(
      () => actRepository.replace(act),
      act,
    );

Future<Act> delete(int actId) => v(
      () => actRepository.wasteById(actId),
      actId,
    );
