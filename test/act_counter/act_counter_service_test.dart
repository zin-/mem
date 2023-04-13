import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../mocks.mocks.dart';
import 'act_counter_service_test.mocks.dart';

@GenerateMocks([
  HomeWidgetAccessor,
])
void main() {
  final mockedMemRepository = MockMemRepository();
  final mockedActRepository = MockActRepository();

  final mockedHomeWidgetAccessor = MockHomeWidgetAccessor();
  HomeWidgetAccessor(instance: mockedHomeWidgetAccessor);

  final actCounterService = ActCounterService(
    memRepository: mockedMemRepository,
    actRepository: mockedActRepository,
  );

  test(
    ': createNew',
    () async {
      final memId = math.Random().nextInt(4294967296);

      final mem = Mem(name: 'createNew', id: memId);
      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) => Future.value(mem));
      final lastUpdatedAt = DateAndTime.now();
      final acts = [
        Act(
          memId,
          DateAndTimePeriod.startNow(),
          createdAt: DateTime.now(),
        ),
        Act(
          memId,
          DateAndTimePeriod(end: lastUpdatedAt),
          createdAt: DateTime.now(),
        ),
      ];
      when(mockedActRepository.shipByMemId(any, period: anyNamed('period')))
          .thenAnswer((realInvocation) => Future.value(acts));
      final homeWidgetId = math.Random().nextInt(4294967296);
      when(mockedHomeWidgetAccessor.initialize(
        methodChannelName,
        initializeMethodName,
      )).thenAnswer((realInvocation) => Future.value(homeWidgetId));
      when(mockedHomeWidgetAccessor.saveWidgetData(any, any))
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockedHomeWidgetAccessor.updateWidget(widgetProviderName))
          .thenAnswer((realInvocation) => Future.value(true));

      await actCounterService.createNew(memId);

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
      verify(mockedHomeWidgetAccessor.initialize(any, any)).called(1);
      expect(
        verify(mockedHomeWidgetAccessor.saveWidgetData(captureAny, captureAny))
            .captured,
        [
          'memId-$homeWidgetId',
          memId,
          'actCount-$memId',
          acts.length,
          'lastUpdatedAtSeconds-$memId',
          lastUpdatedAt.millisecondsSinceEpoch.toDouble(),
          'memName-$memId',
          mem.name,
        ],
      );
      verify(mockedHomeWidgetAccessor.updateWidget(any)).called(1);
    },
    tags: TestSize.small,
  );

  test(
    ': increment',
    () async {
      final memId = math.Random().nextInt(4294967296);

      when(mockedHomeWidgetAccessor.saveWidgetData(any, any))
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockedHomeWidgetAccessor.updateWidget(widgetProviderName))
          .thenAnswer((realInvocation) => Future.value(true));

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

      verifyNever(mockedHomeWidgetAccessor.initialize(any, any));
    },
    tags: TestSize.small,
  );
}
