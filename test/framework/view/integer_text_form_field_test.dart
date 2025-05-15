import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('初期値が正しく表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IntegerTextFormField(42),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('有効な値を入力できる', (WidgetTester tester) async {
    int? changedValue;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IntegerTextFormField(
            0,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.pump();

    expect(changedValue, 123);
  });

  testWidgets('数値以外の入力をバリデーションできる', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(0),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('abc'), l10n.targetInputNumberError);
  });

  testWidgets('負の値をバリデーションできる', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(0),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '-1');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('-1'), l10n.targetInputNegativeError);
  });

  testWidgets('最大値を超える値をバリデーションできる', (WidgetTester tester) async {
    const maxValue = 100;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(0, maxValue: maxValue),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '101');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('101'), l10n.targetInputMaxCountError(maxValue));
  });

  testWidgets('最大値を超える値を入力した場合、onChangedはnullを返す', (WidgetTester tester) async {
    int? changedValue;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: IntegerTextFormField(
            0,
            maxValue: 100,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '101');
    await tester.pump();

    expect(changedValue, null);
  });
}
