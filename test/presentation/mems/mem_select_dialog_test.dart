import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_select_dialog.dart';
import 'package:mem/l10n/l10n.dart';

import '../../entity_factories.dart';
import '../../helpers.dart';

const _title = 'Add Relation';
const _confirmLabel = '追加';
const _cancelLabel = 'キャンセル';

final _now = DateTime(2024, 6, 1);

MemEntity _mem(
  int id,
  String name, {
  DateTime? archivedAt,
}) =>
    savedMem(
      id: id,
      name: name,
      createdAt: _now,
      updatedAt: _now,
      archivedAt: archivedAt,
    );

bool _checked(WidgetTester tester, String name) =>
    tester
        .widget<CheckboxListTile>(
          find.widgetWithText(CheckboxListTile, name),
        )
        .value ==
    true;

Future<void> _open(
  WidgetTester tester, {
  required List<MemEntity> candidates,
  required MemSelectMode mode,
  List<int> selectedMemIds = const [],
  Set<int> excludedMemIds = const <int>{},
  void Function(List<int> ids)? onSubmit,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) => MemSelectDialog(
                candidates: candidates,
                mode: mode,
                excludedMemIds: excludedMemIds,
                selectedMemIds: selectedMemIds,
                title: _title,
                confirmLabel: _confirmLabel,
                cancelLabel: _cancelLabel,
                onSubmit: onSubmit ?? (_) {},
              ),
            );
          },
          child: const Text('Show Dialog'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show Dialog'));
  await tester.pumpAndSettle();
}

void main() {
  group('MemSelectDialog', () {
    testWidgets('shows the title, search field, and candidates',
        (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
        buildL10n(tester.element(find.byType(TextField))).searchMemHint,
      );
      expect(find.text('Mem 1'), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
    });

    testWidgets('checks the mems already selected', (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
        selectedMemIds: const [1],
      );

      expect(_checked(tester, 'Mem 1'), isTrue);
      expect(_checked(tester, 'Mem 2'), isFalse);
    });

    testWidgets('filters candidates by the search text', (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [
          _mem(1, 'Apple'),
          _mem(2, 'Banana'),
          _mem(3, 'Cherry'),
        ],
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(3));

      await tester.enterText(find.byType(TextField), 'Ban');
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('shows every candidate when the search text is empty',
        (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('keeps selected mems when the search text does not match',
        (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Apple'), _mem(2, 'Banana')],
        selectedMemIds: const [1],
      );

      await tester.enterText(find.byType(TextField), 'Ban');
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('toggles a checkbox', (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1')],
        selectedMemIds: const [1],
      );

      expect(_checked(tester, 'Mem 1'), isTrue);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(_checked(tester, 'Mem 1'), isFalse);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(_checked(tester, 'Mem 1'), isTrue);
    });

    testWidgets('hides excluded mems', (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
        excludedMemIds: const {1},
      );

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
      expect(find.text('Mem 1'), findsNothing);
    });

    testWidgets('submits every selected id', (tester) async {
      List<int>? submitted;

      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
        onSubmit: (ids) => submitted = ids,
      );

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Mem 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Mem 2'));
      await tester.pump();

      expect(_checked(tester, 'Mem 1'), isTrue);
      expect(_checked(tester, 'Mem 2'), isTrue);

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(submitted, [1, 2]);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('closes without submitting when cancel is pressed',
        (tester) async {
      var submitted = false;

      await _open(
        tester,
        mode: MemSelectMode.multiple,
        candidates: [_mem(1, 'Mem 1')],
        onSubmit: (_) => submitted = true,
      );

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text(_cancelLabel));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(submitted, isFalse);
    });

    for (final mode in MemSelectMode.values) {
      testWidgets('omits archived mems ($mode)', (tester) async {
        await _open(
          tester,
          mode: mode,
          candidates: [
            _mem(1, 'Active'),
            _mem(2, 'Archived', archivedAt: DateTime(2024, 1, 1)),
          ],
          selectedMemIds: const [2],
        );

        Finder listed(String name) => find.descendant(
              of: find.byType(ListView),
              matching: find.text(name),
            );

        expect(listed('Active'), findsOneWidget);
        expect(listed('Archived'), findsNothing);

        await tester.enterText(find.byType(TextField), 'Archived');
        await tester.pump();

        expect(listed('Active'), findsNothing);
        expect(listed('Archived'), findsNothing);
      });
    }

    testWidgets('single keeps one selection and submits that id',
        (tester) async {
      List<int>? submitted;

      await _open(
        tester,
        mode: MemSelectMode.single,
        candidates: [_mem(1, 'Mem 1'), _mem(2, 'Mem 2')],
        onSubmit: (ids) => submitted = ids,
      );

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(RadioListTile<int>), findsNWidgets(2));

      await tester.tap(find.widgetWithText(RadioListTile<int>, 'Mem 1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(RadioListTile<int>, 'Mem 2'));
      await tester.pump();

      expect(
        tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue,
        2,
      );

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(submitted, [2]);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets(
        'submits nothing when single mode is confirmed with no selection',
        (tester) async {
      List<int>? submitted;

      await _open(
        tester,
        mode: MemSelectMode.single,
        candidates: [_mem(1, 'Mem 1')],
        onSubmit: (ids) => submitted = ids,
      );

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('keeps the single selection when the group reports no value',
        (tester) async {
      await _open(
        tester,
        mode: MemSelectMode.single,
        candidates: [_mem(1, 'Mem 1')],
        selectedMemIds: const [1],
      );

      tester
          .widget<RadioGroup<int>>(find.byType(RadioGroup<int>))
          .onChanged(null);
      await tester.pump();

      expect(
        tester.widget<RadioGroup<int>>(find.byType(RadioGroup<int>)).groupValue,
        1,
      );
    });
  });
}
