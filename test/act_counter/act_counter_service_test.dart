import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter_repository.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/channels.dart';
import 'package:mem/notifications/wrapper.dart';
import 'package:mockito/mockito.dart';

import '../helpers.dart';
import '../helpers.mocks.dart';

void main() {
  LogService.initialize(Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedActRepository = MockActRepository();
  ActRepository.resetWith(mockedActRepository);
  final mockedHomeWidgetAccessor = MockHomeWidgetAccessor();
  HomeWidgetAccessor(instance: mockedHomeWidgetAccessor);
  final mockedNotificationWrapper = MockNotificationsWrapper();
  NotificationsWrapper.resetWith(mockedNotificationWrapper);

  final actCounterService = ActCounterService();

  test(
    ': createNew',
    () async {
      final memId = randomInt();

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
      final homeWidgetId = randomInt();
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
          'memName-$memId',
          mem.name,
          'actCount-$memId',
          acts.length,
          'lastUpdatedAtSeconds-$memId',
          lastUpdatedAt.millisecondsSinceEpoch.toDouble(),
          'memId-$homeWidgetId',
          memId,
        ],
      );
      verify(mockedHomeWidgetAccessor.updateWidget(any)).called(1);
    },
  );

  test(
    ': increment',
    () async {
      prepareNotifications();

      final memId = randomInt();
      final now = DateAndTime.now();

      final act = Act(memId, DateAndTimePeriod.startNow());
      when(mockedActRepository.receive(any))
          .thenAnswer((realInvocation) => Future.value(act));
      final mem = Mem(name: 'createNew', id: memId);
      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) => Future.value(mem));
      final acts = <Act>[
        Act(
          memId,
          DateAndTimePeriod(end: now),
          createdAt: DateTime.now(),
        ),
        Act(
          memId,
          DateAndTimePeriod(end: now),
          createdAt: DateTime.now(),
        ),
      ];
      when(mockedActRepository.shipByMemId(any, period: anyNamed('period')))
          .thenAnswer((realInvocation) => Future.value(acts));
      when(mockedActRepository.replace(any))
          .thenAnswer((realInvocation) => Future.value(act));

      when(mockedHomeWidgetAccessor.saveWidgetData(any, any))
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockedHomeWidgetAccessor.updateWidget(widgetProviderName))
          .thenAnswer((realInvocation) => Future.value(true));

      when(mockedNotificationWrapper.cancel(any))
          .thenAnswer((realInvocation) => null);

      await actCounterService.increment(memId, now);

      expect(
        verify(mockedActRepository.receive(captureAny)).captured[0].memId,
        memId,
      );
      expect(
        verify(mockedMemRepository.shipById(captureAny)).captured,
        [memId, memId],
      );
      expect(
        verify(mockedActRepository.shipByMemId(
          captureAny,
          period: captureAnyNamed('period'),
        )).captured[0],
        memId,
      );

      verifyNever(mockedHomeWidgetAccessor.initialize(any, any));
      expect(
        verify(mockedHomeWidgetAccessor.saveWidgetData(captureAny, captureAny))
            .captured,
        [
          'memName-$memId',
          mem.name,
          'actCount-$memId',
          acts.length,
          'lastUpdatedAtSeconds-$memId',
          now.millisecondsSinceEpoch.toDouble(),
        ],
      );
      verify(mockedHomeWidgetAccessor.updateWidget(any)).called(1);
    },
  );
}
