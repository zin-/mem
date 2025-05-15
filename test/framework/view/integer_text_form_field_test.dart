import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';

void main() {
  testWidgets('displays initial value correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntegerTextFormField(42),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('can input valid value', (WidgetTester tester) async {
    int? changedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntegerTextFormField(
            0,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '123');
    await tester.pump();

    expect(changedValue, 123);
  });

  testWidgets('validates empty input with default message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(0),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator(''), 'Please enter a number');
  });

  testWidgets('validates empty input with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom empty error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              emptyErrorMessage: errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator(''), errorMessage);
  });

  testWidgets('validates non-numeric input with default message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(0),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), 'abc');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('abc'), 'Please enter a number');
  });

  testWidgets('validates non-numeric input with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom non-numeric error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              nonNumericErrorMessage: errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), 'abc');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('abc'), errorMessage);
  });

  testWidgets('validates value below minimum with default message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              minValue: 10,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '5');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('5'), 'Please enter a value greater than or equal to 10');
  });

  testWidgets('validates value below minimum with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom below minimum error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              minValue: 10,
              belowMinErrorMessage: errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '5');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('5'), errorMessage);
  });

  testWidgets('validates value above maximum with default message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              maxValue: 100,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '101');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('101'), 'Please enter a value less than or equal to 100');
  });

  testWidgets('validates value above maximum with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom above maximum error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              maxValue: 100,
              aboveMaxErrorMessage: errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '101');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find
        .descendant(
          of: find.byType(IntegerTextFormField),
          matching: find.byType(TextFormField),
        )
        .first);
    final validator = formField.validator!;
    expect(validator('101'), errorMessage);
  });

  testWidgets(
      'validates on focus change with autovalidateMode.onUserInteraction',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              minValue: 10,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ),
      ),
    );

    // フォーカスを当てる
    await tester.tap(find.byType(IntegerTextFormField));
    await tester.pump();

    // 無効な値を入力
    await tester.enterText(find.byType(IntegerTextFormField), '5');
    await tester.pump();

    // フォーカスを外す
    await tester.tap(find.byType(Scaffold));
    await tester.pump();

    // エラーメッセージが表示されていることを確認
    expect(find.text('Please enter a value greater than or equal to 10'),
        findsOneWidget);
  });

  testWidgets('validates on focus change with autovalidateMode.always',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              minValue: 10,
              autovalidateMode: AutovalidateMode.always,
            ),
          ),
        ),
      ),
    );

    // フォーカスを当てる
    await tester.tap(find.byType(IntegerTextFormField));
    await tester.pump();

    // 無効な値を入力
    await tester.enterText(find.byType(IntegerTextFormField), '5');
    await tester.pump();

    // フォーカスを外す
    await tester.tap(find.byType(Scaffold));
    await tester.pump();

    // エラーメッセージが表示されていることを確認
    expect(find.text('Please enter a value greater than or equal to 10'),
        findsOneWidget);
  });

  testWidgets('returns null when input is out of range',
      (WidgetTester tester) async {
    int? changedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntegerTextFormField(
            0,
            minValue: 10,
            maxValue: 100,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '5');
    await tester.pump();

    expect(changedValue, null);
  });

  testWidgets('returns value when input is within range',
      (WidgetTester tester) async {
    int? changedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntegerTextFormField(
            0,
            minValue: 10,
            maxValue: 100,
            onChanged: (value) => changedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(IntegerTextFormField), '50');
    await tester.pump();

    expect(changedValue, 50);
  });
}
