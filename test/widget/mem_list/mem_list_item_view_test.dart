import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/atoms/state_notifier.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';
import 'package:mem/views/mem_list/mem_list_item_view.dart';
import 'package:mockito/mockito.dart';

import '../../minimum.dart';
import '../../mocks.mocks.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpMemListItemView(WidgetTester widgetTester, int memId) async {
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          memProvider.overrideWithProvider((argument) {
            expect(argument, memId);

            return StateNotifierProvider((ref) => ValueStateNotifier(null));
          })
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => L10n(context).memListPageTitle(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: MemListItemView(memId),
          ),
        ),
      ),
    );
  }

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  tearDown(() => reset(mockedMemRepository));

  testWidgets('Show', (widgetTester) async {
    final savedMemEntity = minSavedMemEntity(1)..name = 'saved mem entity name';

    when(mockedMemRepository.shipById(savedMemEntity.id))
        .thenAnswer((realInvocation) {
      final arg1 = realInvocation.positionalArguments[0];

      expect(arg1, savedMemEntity.id);

      return Future.value(minSavedMemEntity(arg1));
    });

    await pumpMemListItemView(widgetTester, savedMemEntity.id);

    verify(mockedMemRepository.shipById(savedMemEntity.id)).called(1);

    await widgetTester.pump();

    expect(
      (widgetTester.widget(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byType(Text),
        ),
      ) as Text)
          .data,
      savedMemEntity.name,
    );
  });
}
