import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';

final actRepository = ActRepository();

Future<List<Act>> fetchByMemIdIs(MemId memId) =>
    actRepository.shipByMemId(memId);

Future<Act> add(MemId memId) => actRepository.receive(
      Act(
        memId,
        DateAndTimePeriod(
          start: DateAndTime.now(),
          end: DateAndTime.now(),
        ),
      ),
    );
