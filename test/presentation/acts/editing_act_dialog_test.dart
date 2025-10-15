import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/acts/act_entity.dart';

class _FakeActEntities extends ActEntities {
  final Iterable<SavedActEntity> _state;

  _FakeActEntities(this._state);

  @override
  Iterable<SavedActEntity> build() => _state;
}

void main() {
  group('EditingActDialog test', () {
    testWidgets('should not show dialog when target act is not found.',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            actEntitiesProvider.overrideWith(() => _FakeActEntities([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const EditingActDialog(1),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Show Dialog'), findsOneWidget);
    });
  });
}
