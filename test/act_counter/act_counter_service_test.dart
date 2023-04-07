import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  final mockedActRepository = MockActRepository();
  final mockedActCounterRepository = MockActCounterRepository();

  final actCounterService = ActCounterService(
    memRepository: mockedMemRepository,
    actRepository: mockedActRepository,
    actCounterRepository: mockedActCounterRepository,
  );

  test(
    ': createNew',
    () async {
      const memId = 1;

      final actCounter = ActCounter(memId);
      when(mockedActCounterRepository.receive(any))
          .thenAnswer((realInvocation) => Future.value(actCounter));
      final mem = Mem(name: 'createNew', id: memId);
      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) => Future.value(mem));
      final acts = <Act>[
        Act(
          memId,
          DateAndTimePeriod.startNow(),
          createdAt: DateTime.now(),
        ),
        Act(
          memId,
          DateAndTimePeriod(end: DateAndTime.now()),
          createdAt: DateTime.now(),
        ),
      ];
      when(mockedActRepository.shipByMemId(any, period: anyNamed('period')))
          .thenAnswer((realInvocation) => Future.value(acts));
      when(mockedActCounterRepository.replace(any))
          .thenAnswer((realInvocation) => Future.value(actCounter));

      await actCounterService.createNew(memId);

      expect(
        verify(mockedActCounterRepository.receive(captureAny))
            .captured
            .toString(),
        [actCounter].toString(),
      );
      expect(
        verify(mockedMemRepository.shipById(captureAny)).captured,
        [memId],
      );
      expect(
        verify(mockedActRepository.shipByMemId(
          captureAny,
          period: captureAnyNamed('period'),
        )).captured[0],
        memId,
      );
      expect(
        verify(mockedActCounterRepository.replace(captureAny))
            .captured
            .toString(),
        [
          ActCounter(
            memId,
            actCount: acts.length,
            lastUpdatedAt: acts.last.period.end,
            name: mem.name,
          ),
        ].toString(),
      );
    },
  );

  test(
    ': increment',
    () async {
      const memId = 1;

      final act = Act(memId, DateAndTimePeriod.startNow());
      when(mockedActRepository.receive(any))
          .thenAnswer((realInvocation) => Future.value(act));
      final mem = Mem(name: 'createNew', id: memId);
      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) => Future.value(mem));
      final acts = <Act>[
        Act(
          memId,
          DateAndTimePeriod.startNow(),
          createdAt: DateTime.now(),
        ),
        Act(
          memId,
          DateAndTimePeriod(end: DateAndTime.now()),
          createdAt: DateTime.now(),
        ),
      ];
      when(mockedActRepository.shipByMemId(any, period: anyNamed('period')))
          .thenAnswer((realInvocation) => Future.value(acts));
      final actCounter = ActCounter(memId);
      when(mockedActCounterRepository.replace(any))
          .thenAnswer((realInvocation) => Future.value(actCounter));

      await actCounterService.increment(memId);

      expect(
        verify(mockedActRepository.receive(captureAny)).captured[0].memId,
        memId,
      );
      expect(
        verify(mockedMemRepository.shipById(captureAny)).captured,
        [memId],
      );
      expect(
        verify(mockedActRepository.shipByMemId(
          captureAny,
          period: captureAnyNamed('period'),
        )).captured[0],
        memId,
      );
      expect(
        verify(mockedActCounterRepository.replace(captureAny))
            .captured
            .toString(),
        [
          ActCounter(
            memId,
            actCount: acts.length,
            lastUpdatedAt: acts.last.period.end,
            name: mem.name,
          ),
        ].toString(),
      );
    },
  );
}
