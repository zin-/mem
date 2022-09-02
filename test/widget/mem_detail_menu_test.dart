import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/colors.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';

void main() {
  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  tearDown(() {
    reset(mockedMemRepository);
  });

  testWidgets('Open menu', (widgetTester) async {
    await pumpMemDetailPage(widgetTester, null);

    expect(archiveButtonFinder, findsOneWidget);
    expect(unarchiveButtonFinder, findsNothing);
    expect(memDetailMenuButtonFinder, findsOneWidget);

    await widgetTester.tap(memDetailMenuButtonFinder);
    await widgetTester.pump();

    expect(removeButtonFinder, findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('Show remove confirmation dialog', (widgetTester) async {
    await pumpMemDetailPage(widgetTester, null);

    await showRemoveMemConfirmDialog(widgetTester);

    expect(removeConfirmationFinder, findsOneWidget);
    expect(okButtonFinder, findsOneWidget);
    expect(cancelButtonFinder, findsOneWidget);

    await widgetTester.tap(cancelButtonFinder);
    await widgetTester.pumpAndSettle();

    expect(removeConfirmationFinder, findsNothing);
  });

  testWidgets('Show archived', (widgetTester) async {
    const memId = 1;
    const memName = 'test mem name';
    final mem = Mem(
      id: memId,
      name: memName,
      createdAt: DateTime.now(),
      archivedAt: DateTime.now(),
    );

    when(mockedMemRepository.shipWhereIdIs(any))
        .thenAnswer((realInvocation) async => mem);
    when(mockedMemRepository.unarchive(mem)).thenAnswer((realInvocation) async {
      final mem = realInvocation.positionalArguments[0] as Mem;

      return Mem.fromMap(mem.toMap()..['archivedAt'] = null);
    });

    await pumpMemDetailPage(widgetTester, memId);

    expect(archiveButtonFinder, findsNothing);
    expect(unarchiveButtonFinder, findsOneWidget);

    await widgetTester.tap(unarchiveButtonFinder);
    final appBar = widgetTester.widget(appBarFinder) as AppBar;
    expect(appBar.backgroundColor, archivedColor);

    verify(mockedMemRepository.shipWhereIdIs(memId)).called(1);
    verify(mockedMemRepository.unarchive(any)).called(1);
  });
}

final archiveButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.archive),
);

final unarchiveButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.unarchive),
);

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
