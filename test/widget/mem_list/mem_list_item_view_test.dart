import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/views/mems/mem_list/mem_list_item_view.dart';
import 'package:mockito/mockito.dart';

import '../../_helpers.dart';
import '../../samples.dart';
import '../../mocks.mocks.dart';

void main() {
  Logger(level: Level.verbose);

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
        final savedMem = minSavedMem(1)..notifyOn = DateTime.now();

        await pumpMemListItemView(
          widgetTester,
          savedMem,
        );
        await widgetTester.pump();

        expect(
          find.text(DateFormat.yMd().format(savedMem.notifyOn!)),
          findsOneWidget,
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

          final savedMemEntity = minSavedMemEntity(savedMem.id)
            ..name = savedMem.name
            ..doneAt = savedMem.doneAt;
          when(mockedMemRepository.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return savedMemEntity;
          });
          when(mockedMemRepository.update(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<MemEntity>());
            expect(arg1.id, savedMem.id);

            expect(arg1.doneAt, isNotNull);

            return MemEntity.fromMap(arg1.toMap())..updatedAt = DateTime.now();
          });
          when(mockedNotificationRepository.discard(any))
              .thenAnswer((realInvocation) {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return Future.value(null);
          });

          await widgetTester.tap(find.byType(Checkbox));

          verify(mockedMemRepository.shipById(any)).called(1);
          verify(mockedMemRepository.update(any)).called(1);
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

          final savedMemEntity = minSavedMemEntity(savedMem.id)
            ..name = savedMem.name
            ..doneAt = savedMem.doneAt;
          when(mockedMemRepository.shipById(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return savedMemEntity;
          });
          when(mockedMemRepository.update(any))
              .thenAnswer((realInvocation) async {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<MemEntity>());
            expect(arg1.id, savedMem.id);

            expect(arg1.doneAt, isNull);

            return MemEntity.fromMap(arg1.toMap())..updatedAt = DateTime.now();
          });
          when(mockedNotificationRepository.receive(
                  any, any, any, any, any, any, any))
              .thenAnswer((realInvocation) {
            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, savedMem.id);

            return Future.value(null);
          });

          await widgetTester.tap(find.byType(Checkbox));

          verify(mockedMemRepository.shipById(any)).called(1);
          verify(mockedMemRepository.update(any)).called(1);
          verifyNever(mockedMemItemRepository.update(any));
        },
        tags: TestSize.small,
      );
    },
  );
}
