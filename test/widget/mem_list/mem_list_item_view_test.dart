import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/views/mems/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mems/mem_list/mem_list_item_view.dart';
import 'package:mockito/mockito.dart';

import '../../samples.dart';
import '../../mocks.mocks.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpMemListItemView(
    WidgetTester widgetTester,
    MemEntity memEntity,
  ) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          memProvider.overrideWithProvider((argument) {
            expect(argument, memEntity.id);

            return StateNotifierProvider(
                (ref) => ValueStateNotifier(memEntity));
          })
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => L10n(context).memListPageTitle(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MemListItemView(memEntity),
          ),
        ),
      ),
    );
  }

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  tearDown(() => reset(mockedMemRepository));

  testWidgets('Show', (widgetTester) async {
    final savedMemEntity = minSavedMemEntity(1)
      ..name = 'saved mem entity name'
      ..doneAt = null;

    await pumpMemListItemView(
      widgetTester,
      savedMemEntity,
    );
    await widgetTester.pump();

    when(mockedMemRepository.update(any)).thenAnswer((realInvocation) async {
      final arg1 = realInvocation.positionalArguments[0] as MemEntity;

      expect(arg1.doneAt, isNotNull);

      return MemEntity.fromMap(arg1.toMap())..updatedAt = DateTime.now();
    });

    await widgetTester.tap(find.byType(Checkbox));

    verify(mockedMemRepository.update(any)).called(1);
  });
}
