import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';

import '../mocks.mocks.dart';
import 'mem_detail_page_test.dart';

void main() {
  Logger(level: Level.verbose);

  final mockedMemRepository = MockMemRepository();
  MemRepository.withMock(mockedMemRepository);

  testWidgets('Open menu', (widgetTester) async {
    await pumpMemDetailPage(widgetTester, null);

    expect(archiveButtonFinder, findsOneWidget);
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
}

final archiveButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.archive),
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
