import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/mems/mem_detail_states.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_list_page_states.dart';
import 'package:mem/mems/mem_notify_at.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';

import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../samples.dart';
import '../mocks.mocks.dart';

void main() {
  Future pumpMemListItemView(
    WidgetTester widgetTester,
    Mem mem,
  ) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          onGenerateTitle: (context) => L10n(context).memListPageTitle(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MemListItemViewComponent(
              mem,
              (memId) {},
              (value, memId) {},
            ),
          ),
        ),
      ),
    );
  }

  final mockedMemRepositoryV2 = MockMemRepositoryV2();
  MemRepositoryV2.resetWith(mockedMemRepositoryV2);
  final mockedMemItemRepository = MockMemItemRepositoryV2();
  MemItemRepositoryV2.resetWith(mockedMemItemRepository);
  final mockedNotificationRepository = MockNotificationRepository();
  NotificationRepository.reset(mockedNotificationRepository);

  tearDown(() {
    reset(mockedMemRepositoryV2);
    reset(mockedMemItemRepository);
    reset(mockedNotificationRepository);
  });

  group('Show', () {
    testWidgets(
      ': default',
      (widgetTester) async {
        final savedMem = minSavedMem(1)
          ..name = 'saved mem entity name'
          ..doneAt = null;

        await pumpMemListItemView(
          widgetTester,
          savedMem,
        );
        await widgetTester.pump();

        expect(find.text(savedMem.name), findsOneWidget);
        expect(
          widgetTester.widget<Checkbox>(find.byType(Checkbox)).value,
          false,
        );
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': notifyAt',
      (widgetTester) async {
        final savedMem = minSavedMem(1)
          ..notifyAtV2 = DateAndTime.now(allDay: true);

        await pumpMemListItemView(
          widgetTester,
          savedMem,
        );
        await widgetTester.pump();

        final memNotifyAt = widgetTester.widget(find.byType(MemNotifyAtText))
            as MemNotifyAtText;

        expect(
          memNotifyAt.data,
          DateFormat.yMd().format(savedMem.notifyAtV2!),
        );
      },
      tags: TestSize.small,
    );
  });

  group(
    'Action',
    () {
      testWidgets(
        'done',
        (widgetTester) async {
          const memId = 1;

          final savedMem = minSavedMem(memId)
            ..name = 'MemListItemViewTest: Action: done'
            ..doneAt = null;
          final memList = [savedMem];

          await runTestWidgetWithProvider(
            widgetTester,
            Scaffold(
              body: MemListItemView(memId, (memId) {}),
            ),
            overrides: [
              memListProvider
                  .overrideWithValue(ListValueStateNotifier(memList)),
              memProvider(memId)
                  .overrideWithValue(ValueStateNotifier(savedMem)),
            ],
          );
          await widgetTester.pump();

          when(mockedMemRepositoryV2.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, memId);

            return savedMem;
          });
          when(mockedMemRepositoryV2.replace(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0] as Mem;

            expect(arg1.id, memId);
            expect(arg1.doneAt, isNotNull);

            return Mem(
              name: arg1.name,
              doneAt: arg1.doneAt,
              id: arg1.id,
              createdAt: arg1.createdAt,
              updatedAt: DateTime.now(),
            );
          });
          when(mockedNotificationRepository.discard(any))
              .thenAnswer((realInvocation) {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return Future.value(null);
          });

          await widgetTester.tap(find.byType(Checkbox));

          verify(mockedMemRepositoryV2.shipById(memId)).called(1);
          expect(
            verify(mockedMemRepositoryV2.replace(captureAny)).captured,
            [savedMem],
          );
          verify(mockedNotificationRepository.discard(memId)).called(1);

          verifyNever(mockedMemItemRepository.replace(any));
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': undone',
        (widgetTester) async {
          const memId = 1;

          final savedMem = minSavedMem(memId)
            ..name = 'MemListItemViewTest: Action: done'
            ..doneAt = DateTime.now();
          final memList = [savedMem];

          await runTestWidgetWithProvider(
            widgetTester,
            Scaffold(
              body: MemListItemView(memId, (memId) {}),
            ),
            overrides: [
              memListProvider
                  .overrideWithValue(ListValueStateNotifier(memList)),
              memProvider(memId)
                  .overrideWithValue(ValueStateNotifier(savedMem)),
            ],
          );
          await widgetTester.pump();

          when(mockedMemRepositoryV2.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, memId);

            return savedMem;
          });
          when(mockedMemRepositoryV2.replace(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0] as Mem;

            expect(arg1.id, memId);
            expect(arg1.doneAt, isNull);

            return Mem(
              name: arg1.name,
              doneAt: arg1.doneAt,
              id: arg1.id,
              createdAt: arg1.createdAt,
              updatedAt: DateTime.now(),
            );
          });
          when(mockedNotificationRepository.discard(any))
              .thenAnswer((realInvocation) {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return Future.value(null);
          });

          await widgetTester.tap(find.byType(Checkbox));

          verify(mockedMemRepositoryV2.shipById(memId)).called(1);
          expect(
            verify(mockedMemRepositoryV2.replace(captureAny)).captured,
            [savedMem],
          );

          verifyNever(mockedNotificationRepository.discard(any));
          verifyNever(mockedMemItemRepository.replace(any));
        },
        tags: TestSize.small,
      );
    },
  );
}
