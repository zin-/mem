import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/database/database.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/mem_detail/mem_detail_page.dart';
import 'package:mem/views/constants.dart';

import '../mocks.mocks.dart';

void main() {
  Future pumpMemDetailPage(WidgetTester widgetTester, int? memId) async {
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
    await widgetTester.pump();
  }

  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  group('New', () {
    testWidgets(': not found.', (widgetTester) async {
      when(mockedMemRepository.shipWhereIdIs(any))
          .thenThrow(NotFoundException('test target', 'test condition'));

      await pumpMemDetailPage(widgetTester, 1);

      expectMemNameOnMemDetail(widgetTester, '');
      expect(saveFabFinder, findsOneWidget);
      expect(archiveButtonFinder, findsOneWidget);

      verify(mockedMemRepository.shipWhereIdIs(1)).called(1);
    });

    testWidgets(': found.', (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      when(mockedMemRepository.shipWhereIdIs(any))
          .thenAnswer((realInvocation) async => Mem(
                id: memId,
                name: memName,
                createdAt: DateTime.now(),
              ));

      await pumpMemDetailPage(widgetTester, memId);

      expectMemNameOnMemDetail(widgetTester, memName);
      expect(saveFabFinder, findsOneWidget);
      expect(archiveButtonFinder, findsOneWidget);

      verify(mockedMemRepository.shipWhereIdIs(memId)).called(1);
    });
  });

  group('Save', () {
    testWidgets(': create.', (widgetTester) async {
      const enteringMemName = 'entering mem name';

      when(mockedMemRepository.receive(any)).thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0];
        expect(value['name'], enteringMemName);

        return Mem(id: 1, name: value['name'], createdAt: DateTime.now());
      });

      await pumpMemDetailPage(widgetTester, null);

      await enterMemNameAndSave(widgetTester, enteringMemName);

      await checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

      verifyNever(mockedMemRepository.shipWhereIdIs(any));
      verify(mockedMemRepository.receive(any)).called(1);
    });

    testWidgets(': update.', (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      const enteringMemName = 'entering mem name';

      when(mockedMemRepository.shipWhereIdIs(any))
          .thenAnswer((realInvocation) async => Mem(
                id: memId,
                name: memName,
                createdAt: DateTime.now(),
              ));
      when(mockedMemRepository.update(any)).thenAnswer((realInvocation) async {
        final value = realInvocation.positionalArguments[0];
        expect(value.id, memId);
        expect(value.name, enteringMemName);

        return Mem(
          id: value.id,
          name: value.name,
          createdAt: value.createdAt,
          updatedAt: DateTime.now(),
        );
      });

      await pumpMemDetailPage(widgetTester, memId);

      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'test',
            home: MemDetailPage(memId),
          ),
        ),
      );
      await widgetTester.pump();

      await enterMemNameAndSave(widgetTester, enteringMemName);

      checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

      verify(mockedMemRepository.shipWhereIdIs(memId)).called(1);
      verify(mockedMemRepository.update(any)).called(1);
    });
  });
}

final memNameTextFormFieldFinder = find.byType(TextFormField).at(0);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);
final archiveButtonFinder = find.byIcon(Icons.archive);

void expectMemNameOnMemDetail(
  WidgetTester widgetTester,
  String memName,
) =>
    expect(
      (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField)
          .initialValue,
      memName,
    );

Future<void> enterMemNameAndSave(
  WidgetTester widgetTester,
  String enteringText,
) async {
  await widgetTester.enterText(memNameTextFormFieldFinder, enteringText);
  await widgetTester.tap(saveFabFinder);
  await widgetTester.pumpAndSettle();
}

Future<void> checkSavedSnackBarAndDismiss(
  WidgetTester widgetTester,
  String memName,
) async {
  expect(find.text('Save success. $memName'), findsOneWidget);

  await widgetTester.pumpAndSettle(defaultDismissDuration);

  expect(find.text('Save success. $memName'), findsNothing);
}
