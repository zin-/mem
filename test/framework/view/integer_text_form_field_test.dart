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

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.pump();

    expect(changedValue, 123);
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

    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('abc'), 'Please enter a number');
  });

  testWidgets('validates non-numeric input with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              errorMessageBuilder: (_) => errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
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

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('5'), 'Please enter a value greater than or equal to 10');
  });

  testWidgets('validates value below minimum with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              minValue: 10,
              errorMessageBuilder: (_) => errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
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

    await tester.enterText(find.byType(TextFormField), '101');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('101'), 'Please enter a value less than or equal to 100');
  });

  testWidgets('validates value above maximum with custom message',
      (WidgetTester tester) async {
    const errorMessage = 'Custom error message';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: IntegerTextFormField(
              0,
              maxValue: 100,
              errorMessageBuilder: (_) => errorMessage,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '101');
    await tester.pump();

    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    final validator = formField.validator!;
    expect(validator('101'), errorMessage);
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

    await tester.enterText(find.byType(TextFormField), '5');
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

    await tester.enterText(find.byType(TextFormField), '50');
    await tester.pump();

    expect(changedValue, 50);
  });
}
