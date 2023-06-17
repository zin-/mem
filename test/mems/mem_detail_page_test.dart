import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/mems/mem_detail_body.dart';
import 'package:mem/mems/mem_detail_page.dart';
import 'package:mockito/mockito.dart';
import 'package:mem/gui/l10n.dart';

import '../helpers.mocks.dart';
import '../samples.dart';

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
