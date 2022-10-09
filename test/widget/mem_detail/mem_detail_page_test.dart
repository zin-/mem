import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/services/notification_service.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_body.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_page.dart';
import 'package:mockito/mockito.dart';
import 'package:mem/l10n.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/constants.dart';

import '../../_helpers.dart';
import '../../samples.dart';
import '../../mocks.mocks.dart';
import '../atoms/date_and_time_text_form_field_test.dart';
import 'mem_detail_body_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.reset(mockedMemItemRepository);
  final mockedNotificationRepository = MockNotificationRepository();
  NotificationRepository.reset(mockedNotificationRepository);

  tearDown(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
    reset(mockedNotificationRepository);
  });

  group('Show', () {
    testWidgets(
      ': found Mem',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1);
        when(mockedMemRepository.shipById(savedMemEntity.id))
            .thenAnswer((realInvocation) async => savedMemEntity);
        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1);
        when(mockedMemItemRepository.shipByMemId(savedMemEntity.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, savedMemEntity.id);

        verify(mockedMemRepository.shipById(savedMemEntity.id)).called(1);
        verify(mockedMemItemRepository.shipByMemId(savedMemEntity.id))
            .called(1);

        await widgetTester.pumpAndSettle();

        expect(find.byType(MemDetailBody), findsOneWidget);
        expect(saveFabFinder, findsOneWidget);
      },
      tags: TestSize.small,
    );
  });

  group('Save', () {
    testWidgets(
      ': create.',
      (widgetTester) async {
        const memId = 1;

        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, null);

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'test mem memo';
        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        await pickNowDate(widgetTester);
        await widgetTester.pump();
        await tapAllDaySwitch(widgetTester);
        await pickNowTimeOfDay(widgetTester);
        await widgetTester.pump();

        when(mockedMemRepository.receive(any))
            .thenAnswer((realInvocation) async {
          final value = realInvocation.positionalArguments[0];

          expect(value.name, enteringMemName);
          expect(value.notifyOn, isNotNull);
          expect(value.notifyAt, isNotNull);

          return value
            ..id = memId
            ..createdAt = DateTime.now()
            // 通知の確認をしたいので、将来日付を返却する
            ..notifyOn = DateTime.now().add(const Duration(days: 1));
        });
        when(mockedMemItemRepository.receive(any))
            .thenAnswer((realInvocation) async {
          final value = realInvocation.positionalArguments[0];

          expect(value.memId, memId);
          expect(value.type, MemItemType.memo);
          expect(value.value, enteringMemMemo);

          return value
            ..memId = memId
            ..id = 1
            ..createdAt = DateTime.now();
        });
        when(mockedNotificationRepository.receive(
          memId,
          enteringMemName,
          any,
          any,
          memReminderChannelId,
          any,
          any,
        )).thenAnswer((realInvocation) {
          return Future.value(null);
        });

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle();

        verify(mockedMemRepository.receive(any)).called(1);
        verify(mockedMemItemRepository.receive(any)).called(1);
        verify(mockedNotificationRepository.receive(
                any, any, any, any, any, any, any))
            .called(1);

        expect(saveMemSuccessFinder(enteringMemName), findsOneWidget);

        await widgetTester.pumpAndSettle(defaultDismissDuration);

        expect(saveMemSuccessFinder(enteringMemName), findsNothing);

        verifyNever(mockedMemRepository.shipById(any));
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': update.',
      (widgetTester) async {
        final savedMemEntity = minSavedMemEntity(1);
        when(mockedMemRepository.shipById(savedMemEntity.id))
            .thenAnswer((realInvocation) async => savedMemEntity);
        final savedMemoMemItemEntity =
            minSavedMemoMemItemEntity(savedMemEntity.id, 1);
        when(mockedMemItemRepository.shipByMemId(any))
            .thenAnswer((realInvocation) async => [savedMemoMemItemEntity]);

        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, savedMemEntity.id);
        await widgetTester.pump();

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        when(mockedMemRepository.update(any))
            .thenAnswer((realInvocation) async {
          final memEntity = realInvocation.positionalArguments[0] as MemEntity;

          expect(memEntity.id, savedMemEntity.id);
          expect(memEntity.name, enteringMemName);
          expect(memEntity.createdAt, savedMemEntity.createdAt);
          expect(memEntity.updatedAt, savedMemEntity.updatedAt);
          expect(memEntity.archivedAt, savedMemEntity.archivedAt);

          return memEntity..updatedAt = DateTime.now();
        });
        when(mockedMemItemRepository.update(any))
            .thenAnswer((realInvocation) async {
          final memItemEntity =
              realInvocation.positionalArguments[0] as MemItemEntity;
          expect(memItemEntity.memId, savedMemoMemItemEntity.memId);
          expect(memItemEntity.type, savedMemoMemItemEntity.type);
          expect(memItemEntity.value, enteringMemMemo);
          expect(memItemEntity.createdAt, savedMemoMemItemEntity.createdAt);
          expect(memItemEntity.updatedAt, savedMemoMemItemEntity.updatedAt);
          expect(memItemEntity.archivedAt, savedMemoMemItemEntity.archivedAt);

          return memItemEntity..updatedAt = DateTime.now();
        });

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle();

        verify(mockedMemRepository.update(any)).called(1);
        verify(mockedMemItemRepository.update(any)).called(1);

        expect(saveMemSuccessFinder(enteringMemName), findsOneWidget);

        await widgetTester.pumpAndSettle(defaultDismissDuration);

        expect(saveMemSuccessFinder(enteringMemName), findsNothing);
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': name is required.',
      (widgetTester) async {
        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, null);

        await widgetTester.tap(saveFabFinder);

        expect(find.text('Name is required'), findsNothing);

        verifyNever(mockedMemRepository.shipById(any));
        verifyNever(mockedMemRepository.receive(any));
      },
      tags: TestSize.small,
    );
  });
}

Future pumpMemDetailPage(
  WidgetTester widgetTester,
  int? memId,
) async {
  await widgetTester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        onGenerateTitle: (context) => L10n(context).memDetailPageTitle(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MemDetailPage(memId),
      ),
    ),
  );
  await widgetTester.pumpAndSettle();
}

final saveFabFinder = find.byIcon(Icons.save_alt).at(0);

Finder saveMemSuccessFinder(String memName) =>
    find.text('Save success. $memName');
