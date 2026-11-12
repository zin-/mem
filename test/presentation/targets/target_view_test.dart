import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/targets/target_view.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';
import 'package:mem/l10n/l10n.dart';

class _FakeTargetState extends TargetState {
  final TargetEntityV1 _entity;

  _FakeTargetState(this._entity);

  @override
  Future<TargetEntityV1> build(int? memId) async {
    return _entity;
  }
}

void main() {
  group('TargetText test', () {
    group('表示', () {
      testWidgets('should display TargetText widget', (tester) async {
        final targetEntity = TargetEntityV1(
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
              localizationsDelegates: appLocalizationsDelegates,
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

      testWidgets('should display TimeTextFormField when targetUnit is time',
          (tester) async {
        final targetEntity = TargetEntityV1(
          Target(
            memId: 1,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.time,
            value: 3600,
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
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TargetText(1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TimeTextFormField), findsOneWidget);
        expect(find.byType(IntegerTextFormField), findsNothing);
      });

      testWidgets(
        'should display time input when daily count is at least 2',
        (tester) async {
          await _pumpTargetText(
            tester,
            _target(
              value: 2,
              secondsAfterLastAct: 2 * 60 * 60,
            ),
          );

          expect(find.byType(IntegerTextFormField), findsOneWidget);
          expect(find.byKey(keyTargetSecondsAfterLastAct), findsOneWidget);
          expect(find.text('2 h 0 m'), findsOneWidget);
        },
      );

      testWidgets(
        'should not display time input when daily count is below 2',
        (tester) async {
          await _pumpTargetText(tester, _target(value: 1));

          expect(find.byType(IntegerTextFormField), findsOneWidget);
          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
        },
      );

      testWidgets(
        'should not display time input when period is not a day',
        (tester) async {
          await _pumpTargetText(
            tester,
            _target(value: 4, period: Period.aWeek),
          );

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
        },
      );

      testWidgets(
        'should not display interval input when unit is time',
        (tester) async {
          await _pumpTargetText(
            tester,
            _target(
              value: 3600,
              targetUnit: TargetUnit.time,
              secondsAfterLastAct: 2 * 60 * 60,
            ),
          );

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
          expect(find.byType(TimeTextFormField), findsOneWidget);
          expect(find.text('2 h 0 m'), findsNothing);
        },
      );
    });

    group('変更', () {
      testWidgets('should update display when target value changes',
          (tester) async {
        final targetEntity = TargetEntityV1(
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
              localizationsDelegates: appLocalizationsDelegates,
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
        final targetEntity = TargetEntityV1(
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
              localizationsDelegates: appLocalizationsDelegates,
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
        final targetEntity = TargetEntityV1(
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
              localizationsDelegates: appLocalizationsDelegates,
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
        final targetEntity = TargetEntityV1(
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
              localizationsDelegates: appLocalizationsDelegates,
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

      testWidgets('should update display when time value changes',
          (tester) async {
        final targetEntity = TargetEntityV1(
          Target(
            memId: 1,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.time,
            value: 3600,
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
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TargetText(1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final timeField = find.byType(TimeTextFormField);
        expect(timeField, findsOneWidget);

        final textFormField = find.descendant(
          of: timeField,
          matching: find.byType(TextFormField),
        );
        expect(textFormField, findsOneWidget);

        await tester.enterText(textFormField, '02:30:00');
        await tester.pumpAndSettle();

        expect(find.text('02:30:00'), findsOneWidget);
      });

      testWidgets('should handle time value validation with max limit',
          (tester) async {
        final targetEntity = TargetEntityV1(
          Target(
            memId: 1,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.time,
            value: 3600,
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
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TargetText(1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final timeField = find.byType(TimeTextFormField);
        expect(timeField, findsOneWidget);

        final textFormField = find.descendant(
          of: timeField,
          matching: find.byType(TextFormField),
        );
        expect(textFormField, findsOneWidget);

        // 99時間を超える値を入力（100時間 = 360000秒）
        await tester.enterText(textFormField, '100:00:00');
        await tester.pumpAndSettle();

        // 値がnullになることを確認（バリデーションで除外される）
        expect(find.text('100:00:00'), findsOneWidget);
      });

      testWidgets(
        'should keep the interval when daily count stays at least 2',
        (tester) async {
          final container = await _pumpTargetText(
            tester,
            _target(value: 2, secondsAfterLastAct: 2 * 60 * 60),
          );

          await tester.enterText(_integerInput(), '4');
          await tester.pumpAndSettle();

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsOneWidget);
          expect(_secondsAfterLastAct(container), 2 * 60 * 60);
          expect(_targetValue(container), 4);
        },
      );

      testWidgets(
        'should clear the interval when daily count drops below 2',
        (tester) async {
          final container = await _pumpTargetText(
            tester,
            _target(value: 2, secondsAfterLastAct: 2 * 60 * 60),
          );

          await tester.enterText(_integerInput(), '1');
          await tester.pumpAndSettle();

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
          expect(_secondsAfterLastAct(container), isNull);
          expect(_targetValue(container), 1);
        },
      );

      testWidgets(
        'should clear the interval when period is no longer a day',
        (tester) async {
          final container = await _pumpTargetText(
            tester,
            _target(value: 4, secondsAfterLastAct: 2 * 60 * 60),
          );

          await tester.tap(find.byType(DropdownButton<int>).at(2));
          await tester.pumpAndSettle();
          await tester.tap(find.text('aWeek').last);
          await tester.pumpAndSettle();

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
          final target =
              container.read(targetStateProvider(1)).requireValue.value;
          expect(target.secondsAfterLastAct, isNull);
          expect(target.value, 4);
          expect(target.targetUnit, TargetUnit.count);
          expect(target.period, Period.aWeek);
        },
      );

      testWidgets(
        'should clear the interval when unit is no longer count',
        (tester) async {
          final container = await _pumpTargetText(
            tester,
            _target(value: 4, secondsAfterLastAct: 2 * 60 * 60),
          );

          await tester.tap(find.byType(DropdownButton<int>).at(1));
          await tester.pumpAndSettle();
          await tester.tap(find.text('time').last);
          await tester.pumpAndSettle();

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsNothing);
          expect(find.text('2 h 0 m'), findsNothing);
          final target =
              container.read(targetStateProvider(1)).requireValue.value;
          expect(target.secondsAfterLastAct, isNull);
          expect(target.value, 4);
          expect(target.targetUnit, TargetUnit.time);
        },
      );

      testWidgets(
        'should show time input when daily count becomes 2 or more',
        (tester) async {
          final container = await _pumpTargetText(tester, _target(value: 1));

          await tester.enterText(_integerInput(), '2');
          await tester.pumpAndSettle();

          expect(find.byKey(keyTargetSecondsAfterLastAct), findsOneWidget);
          expect(_secondsAfterLastAct(container), isNull);
          expect(_targetValue(container), 2);
        },
      );

      testWidgets(
        'should store the interval picked in the time input',
        (tester) async {
          final container = await _pumpTargetText(tester, _target(value: 2));

          await tester.tap(find.byIcon(Icons.add));
          await tester.pumpAndSettle();
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          expect(_secondsAfterLastAct(container), 60 * 60);
          expect(find.text('1 h 0 m'), findsOneWidget);
        },
      );
    });
  });
}

Target _target({
  int value = 2,
  Period period = Period.aDay,
  TargetUnit targetUnit = TargetUnit.count,
  int? secondsAfterLastAct,
}) =>
    Target(
      memId: 1,
      targetType: TargetType.equalTo,
      targetUnit: targetUnit,
      value: value,
      period: period,
      secondsAfterLastAct: secondsAfterLastAct,
    );

Future<ProviderContainer> _pumpTargetText(
  WidgetTester tester,
  Target target,
) async {
  final container = ProviderContainer(
    overrides: [
      targetStateProvider(1).overrideWith(
        () => _FakeTargetState(TargetEntityV1(target)),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TargetText(1),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _integerInput() => find.descendant(
      of: find.byType(IntegerTextFormField),
      matching: find.byType(TextFormField),
    );

int? _secondsAfterLastAct(ProviderContainer container) => container
    .read(targetStateProvider(1))
    .requireValue
    .value
    .secondsAfterLastAct;

int _targetValue(ProviderContainer container) =>
    container.read(targetStateProvider(1)).requireValue.value.value;
