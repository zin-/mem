import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/targets/target_view.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';

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
    group('表示', () {
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

    group('変更', () {
      testWidgets('should update display when target value changes',
          (tester) async {
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

        final integerField = find.byType(IntegerTextFormField);
        expect(integerField, findsOneWidget);

        final textFormField = find.descendant(
          of: integerField,
          matching: find.byType(TextFormField),
        );
        expect(textFormField, findsOneWidget);

        await tester.enterText(textFormField, '20');
        await tester.pumpAndSettle();

        expect(find.text('20'), findsOneWidget);
      });

      testWidgets('should update display when target type changes',
          (tester) async {
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

        final dropdownButtons = find.byType(DropdownButton<int>);
        expect(dropdownButtons, findsNWidgets(3));

        final firstDropdown = dropdownButtons.first;
        await tester.tap(firstDropdown);
        await tester.pumpAndSettle();

        final dropdownMenuItem = find.text('moreThan').last;
        await tester.tap(dropdownMenuItem);
        await tester.pumpAndSettle();

        final updatedDropdown =
            tester.widget<DropdownButton<int>>(firstDropdown);
        expect(updatedDropdown.value, equals(TargetType.moreThan.index));
      });

      testWidgets('should update display when target unit changes',
          (tester) async {
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

        final dropdownButtons = find.byType(DropdownButton<int>);
        expect(dropdownButtons, findsNWidgets(3));

        final secondDropdown = dropdownButtons.at(1);
        await tester.tap(secondDropdown);
        await tester.pumpAndSettle();

        final timeMenuItem = find.text('time').last;
        await tester.tap(timeMenuItem);
        await tester.pumpAndSettle();

        final updatedDropdown =
            tester.widget<DropdownButton<int>>(secondDropdown);
        expect(updatedDropdown.value, equals(TargetUnit.time.index));
      });

      testWidgets('should update display when target period changes',
          (tester) async {
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

        final dropdownButtons = find.byType(DropdownButton<int>);
        expect(dropdownButtons, findsNWidgets(3));

        final thirdDropdown = dropdownButtons.at(2);
        await tester.tap(thirdDropdown);
        await tester.pumpAndSettle();

        final weekMenuItem = find.text('aWeek').last;
        await tester.tap(weekMenuItem);
        await tester.pumpAndSettle();

        final updatedDropdown =
            tester.widget<DropdownButton<int>>(thirdDropdown);
        expect(updatedDropdown.value, equals(Period.aWeek.index));
      });
    });
  });
}
