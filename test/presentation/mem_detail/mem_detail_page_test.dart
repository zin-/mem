import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mem/features/mems/detail/page.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/l10n/l10n.dart';

import 'mem_detail_page_test.mocks.dart';

class _TestConstants {
  static const int testMemId = 1;
}

Widget _createTestWidget({
  int? memId,
}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Test App'),
        actions: memId != null ? [const Icon(Icons.more_vert)] : null,
        backgroundColor: memId != null ? Colors.grey : null,
      ),
      body: const Center(
        child: Text('Test Body'),
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      ),
    ),
  );
}

Future<void> _pumpAndSettle(
  WidgetTester tester, {
  int? memId,
}) async {
  await tester.pumpWidget(_createTestWidget(memId: memId));
  await tester.pumpAndSettle();
}

@GenerateMocks([MemClient])
void main() {
  final mockMemClient = MockMemClient();

  MemClient(mock: mockMemClient);

  tearDown(() {
    reset(mockMemClient);
  });

  group('MemDetailPage test', () {
    group('should display', () {
      testWidgets('basic structure for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
        expect(appBar.backgroundColor, isNull);
      });

      testWidgets('basic structure for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.backgroundColor, isNotNull);
      });
    });

    group('should show', () {
      testWidgets('app bar actions for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.length, greaterThan(0));
      });

      testWidgets('no app bar actions for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
      });
    });

    group('should save', () {
      testWidgets('mem when save FAB is tapped with valid input.',
          (tester) async {
        const testMemName = 'Test Mem';

        when(mockMemClient.save(
          any,
          any,
          any,
          any,
          any,
        )).thenAnswer((_) async => (
              (
                MemEntity(Mem("", null, null)),
                <MemItemEntity>[],
                null,
                null,
                null
              ),
              null,
            ));

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: const MemDetailPage(null),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final nameField = find.byKey(keyMemName);
        expect(nameField, findsOneWidget);

        await tester.enterText(nameField, testMemName);
        await tester.pumpAndSettle();

        final saveFab = find.byKey(keySaveMemFab);
        expect(saveFab, findsOneWidget);

        await tester.tap(saveFab);
        await tester.pumpAndSettle();

        verify(mockMemClient.save(
          any,
          any,
          any,
          any,
          any,
        )).called(1);
        expect(find.byType(SnackBar), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final expectedMessage = buildL10n().saveMemSuccessMessage(testMemName);
        expect(snackBar.content, isA<Text>());
        expect((snackBar.content as Text).data, equals(expectedMessage));
      });
    });
  });
}
