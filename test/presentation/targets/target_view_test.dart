import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/targets/target_view.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

class _FakeTargetState extends TargetState {
  final TargetEntity _entity;

  _FakeTargetState(this._entity);

  @override
  Future<TargetEntity> build(int? memId) async {
    return _entity;
  }
}

void main() {
  group('TargetText test', () {
    testWidgets('should display TargetText widget', (tester) async {
      final targetEntity = TargetEntity(
        Target(
          memId: 1,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 10,
          period: Period.aDay,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            targetStateProvider(1).overrideWith(
              () => _FakeTargetState(targetEntity),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TargetText(1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TargetText), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
