import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/gui/colors.dart';
import 'package:mockito/mockito.dart';

import '../_helpers.dart';
import '../mocks.mocks.dart';
import '../samples.dart';
import 'mem_detail_page_test.dart';

void main() {
  final mockedMemRepository = MockMemRepository();
  MemRepository.resetWith(mockedMemRepository);
  final mockedMemItemRepository = MockMemItemRepository();
  MemItemRepository.resetWith(mockedMemItemRepository);

  tearDown(() {
    reset(mockedMemRepository);
    reset(mockedMemItemRepository);
  });

  testWidgets(
    'Open menu',
    (widgetTester) async {
      await pumpMemDetailPage(widgetTester, null);

      expect(archiveButtonFinder, findsOneWidget);
      expect(unarchiveButtonFinder, findsNothing);
      expect(memDetailMenuButtonFinder, findsOneWidget);

      await widgetTester.tap(memDetailMenuButtonFinder);
      await widgetTester.pump();

      expect(removeButtonFinder, findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Show remove confirmation dialog',
    (widgetTester) async {
      await pumpMemDetailPage(widgetTester, null);

      await showRemoveMemConfirmDialog(widgetTester);

      expect(removeConfirmationFinder, findsOneWidget);
      expect(okButtonFinder, findsOneWidget);
      expect(cancelButtonFinder, findsOneWidget);

      await widgetTester.tap(cancelButtonFinder);
      await widgetTester.pumpAndSettle();

      expect(removeConfirmationFinder, findsNothing);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'Show archived and unarchive',
    (widgetTester) async {
      const memId = 1;
      const memName = 'test mem name';
      const memMemo = 'test mem memo';
      final mem = minSavedMem(memId)
        ..name = memName
        ..createdAt = DateTime.now()
        ..archivedAt = DateTime.now();

      when(mockedMemRepository.shipById(any))
          .thenAnswer((realInvocation) async => mem);
      when(mockedMemItemRepository.shipByMemId(any)).thenAnswer(
          (realInvocation) async =>
              [minSavedMemItem(memId, 1, value: memMemo)]);
      when(mockedMemRepository.unarchive(any))
          .thenAnswer((realInvocation) async {
        final mem = realInvocation.positionalArguments[0] as Mem;

        return mem..archivedAt = null;
      });
      when(mockedMemItemRepository.unarchiveByMemId(memId))
          .thenAnswer((realInvocation) async {
        return [
          minSavedMemItem(memId, 1, value: memMemo)..archivedAt = DateTime.now()
        ];
      });

      await pumpMemDetailPage(widgetTester, memId);

      expect(archiveButtonFinder, findsNothing);
      expect(unarchiveButtonFinder, findsOneWidget);

      await widgetTester.tap(unarchiveButtonFinder);
      expect(memDetailAppBar(widgetTester).backgroundColor, archivedColor);

      verify(mockedMemRepository.shipById(memId)).called(1);
      verify(mockedMemRepository.unarchive(any)).called(1);
    },
    tags: TestSize.small,
  );
}

final appBarFinder = find.byType(AppBar);

final archiveButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.archive),
);

final unarchiveButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.unarchive),
);

AppBar memDetailAppBar(WidgetTester widgetTester) =>
    (widgetTester.widget(appBarFinder)) as AppBar;

final memDetailMenuButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.more_vert),
);

Future<void> showRemoveMemConfirmDialog(WidgetTester widgetTester) async {
  await widgetTester.tap(memDetailMenuButtonFinder);
  await widgetTester.pumpAndSettle();

  await widgetTester.tap(removeButtonFinder);
  await widgetTester.pump();
}

final removeButtonFinder = find.byIcon(Icons.delete);
final removeConfirmationFinder = find.text('Can I remove this?');
final cancelButtonFinder = find.text('Cancel');
final okButtonFinder = find.text('OK');
