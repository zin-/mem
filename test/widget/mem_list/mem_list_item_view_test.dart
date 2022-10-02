import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mems/mem_list/mem_list_item_view.dart';
import 'package:mockito/mockito.dart';

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
            body: MemListItemView(mem),
          ),
        ),
      ),
    );
  }

  final mockedMemRepository = MockMemRepository();
  MemRepository.reset(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.reset(mockedMemItemRepository);

  setUp(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
  });

  testWidgets('Show', (widgetTester) async {
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
  });

  testWidgets(
    'Undone',
    (widgetTester) async {
      final savedMem = minSavedMem(1)
        ..name = 'saved mem entity name'
        ..doneAt = DateTime.now();

      await pumpMemListItemView(
        widgetTester,
        savedMem,
      );
      await widgetTester.pump();

      when(mockedMemRepository.update(any)).thenAnswer((realInvocation) async {
        final arg1 = realInvocation.positionalArguments[0] as MemEntity;

        expect(arg1.doneAt, isNotNull);

        return MemEntity.fromMap(arg1.toMap())..updatedAt = DateTime.now();
      });

      await widgetTester.tap(find.byType(Checkbox));

      verify(mockedMemRepository.update(any)).called(1);
      verifyNever(mockedMemItemRepository.update(any));
    },
  );
}
