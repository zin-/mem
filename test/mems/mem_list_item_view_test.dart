import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_notify_at.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';

import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
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
            body: MemListItemView(mem, () {}),
          ),
        ),
      ),
    );
  }

  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
  final mockedMemRepositoryV2 = MockMemRepositoryV2();
  MemRepositoryV2.resetWith(mockedMemRepositoryV2);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.reset(mockedMemItemRepository);
  final mockedNotificationRepository = MockNotificationRepository();
  NotificationRepository.reset(mockedNotificationRepository);

  setUp(() {
    reset(mockedMemRepository);
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
        ': done',
        (widgetTester) async {
          final savedMem = minSavedMem(1)
            ..name = 'saved mem entity name'
            ..doneAt = null;

          await pumpMemListItemView(
            widgetTester,
            savedMem,
          );
          await widgetTester.pump();

          when(mockedMemRepositoryV2.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return savedMem;
          });
          when(mockedMemRepositoryV2.replace(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0] as Mem;

            expect(arg1, isA<Mem>());
            expect(arg1.id, savedMem.id);
            expect(arg1.doneAt, isNotNull);

            return Mem(
              name: arg1.name,
              doneAt: arg1.doneAt,
              id: arg1.id,
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

          verify(mockedMemRepositoryV2.shipById(any)).called(1);
          verify(mockedMemRepositoryV2.replace(any)).called(1);
          verify(mockedNotificationRepository.discard(any)).called(1);
          verifyNever(mockedMemItemRepository.update(any));
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': undone',
        (widgetTester) async {
          final savedMem = minSavedMem(1)
            ..name = 'saved mem entity name'
            ..doneAt = DateTime.now();

          await pumpMemListItemView(
            widgetTester,
            savedMem,
          );
          await widgetTester.pump();

          when(mockedMemRepositoryV2.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return savedMem;
          });
          when(mockedMemRepositoryV2.replace(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<Mem>());
            expect(arg1.id, savedMem.id);
            expect(arg1.doneAt, isNull);
            return Mem(
              name: arg1.name,
              doneAt: arg1.doneAt,
              id: arg1.id,
              updatedAt: DateTime.now(),
            );
          });
          when(mockedNotificationRepository.receive(
                  any, any, any, any, any, any, any))
              .thenAnswer((realInvocation) {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return Future.value(null);
          });

          await widgetTester.tap(find.byType(Checkbox));

          verify(mockedMemRepositoryV2.shipById(savedMem.id)).called(1);
          verify(mockedMemRepositoryV2.replace(any)).called(1);
          verifyNever(mockedMemItemRepository.update(any));
        },
        tags: TestSize.small,
      );
    },
  );
}
