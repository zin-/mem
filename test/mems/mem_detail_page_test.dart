import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:mem/mems/mem_detail_body.dart';
import 'package:mem/mems/mem_detail_page.dart';
import 'package:mockito/mockito.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/gui/constants.dart';

import '../samples.dart';
import '../mocks.mocks.dart';
import 'mem_detail_body_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.resetWith(mockedMemItemRepository);
  final mockedNotificationRepository = MockNotificationRepository();
  NotificationRepository.reset(mockedNotificationRepository);

  tearDown(() {
    reset(mockedMemItemRepository);
    reset(mockedNotificationRepository);
  });

  group('Show', () {
    testWidgets(
      ': found Mem',
      (widgetTester) async {
        final savedMem = minSavedMem(1);
        when(mockedMemRepository.shipById(savedMem.id))
            .thenAnswer((realInvocation) async => savedMem);
        final savedMemoMemItemEntity = minSavedMemItem(savedMem.id, 1);
        when(mockedMemItemRepository.shipByMemId(savedMem.id)).thenAnswer(
            (realInvocation) => Future.value([savedMemoMemItemEntity]));

        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, savedMem.id);

        verify(mockedMemRepository.shipById(savedMem.id)).called(1);
        verify(mockedMemItemRepository.shipByMemId(savedMem.id)).called(1);

        await widgetTester.pumpAndSettle();

        expect(find.byType(MemDetailBody), findsOneWidget);
        expect(saveFabFinder, findsOneWidget);
      },
    );
  });

  group('Save', () {
    testWidgets(
      ': update.',
      (widgetTester) async {
        const memId = 1;

        final savedMem = minSavedMem(memId);
        when(mockedMemRepository.shipById(any))
            .thenAnswer((realInvocation) async => savedMem);
        final savedMemoMemItemEntity = minSavedMemItem(savedMem.id, 1);
        when(mockedMemItemRepository.shipByMemId(any))
            .thenAnswer((realInvocation) async => [savedMemoMemItemEntity]);

        when(mockedNotificationRepository.initialize(any, any))
            .thenAnswer((realInvocation) => Future.value(true));

        await pumpMemDetailPage(widgetTester, savedMem.id);

        verify(mockedMemRepository.shipById(savedMem.id)).called(1);

        await widgetTester.pump();

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        when(mockedMemRepository.replace(any))
            .thenAnswer((realInvocation) async {
          final mem = realInvocation.positionalArguments[0] as Mem;

          expect(mem.id, savedMem.id);
          expect(mem.name, enteringMemName);
          expect(mem.createdAt, savedMem.createdAt);
          expect(mem.updatedAt, savedMem.updatedAt);
          expect(mem.archivedAt, savedMem.archivedAt);

          return mem
            ..updatedAt = DateTime.now()
            ..
                // 通知を登録したいので、翌日を設定する
                notifyAt =
                DateAndTime.now(allDay: true).add(const Duration(days: 1));
        });
        when(mockedMemItemRepository.replace(any))
            .thenAnswer((realInvocation) async {
          final memItem = realInvocation.positionalArguments[0] as MemItem;

          expect(memItem.memId, savedMemoMemItemEntity.memId);
          expect(memItem.type, savedMemoMemItemEntity.type);
          expect(memItem.value, enteringMemMemo);
          expect(memItem.createdAt, savedMemoMemItemEntity.createdAt);
          expect(memItem.updatedAt, savedMemoMemItemEntity.updatedAt);
          expect(memItem.archivedAt, savedMemoMemItemEntity.archivedAt);

          return memItem..updatedAt = DateTime.now();
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

        verify(mockedMemRepository.replace(any)).called(1);
        verify(mockedMemItemRepository.replace(any)).called(1);
        verify(mockedNotificationRepository.receive(
                any, any, any, any, any, any, any))
            .called(1);

        expect(saveMemSuccessFinder(enteringMemName), findsOneWidget);

        await widgetTester.pumpAndSettle(defaultDismissDuration);

        expect(saveMemSuccessFinder(enteringMemName), findsNothing);
      },
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
