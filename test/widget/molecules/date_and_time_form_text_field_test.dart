import 'package:flutter_test/flutter_test.dart';
import 'package:mem/views/atoms/date_and_time_view.dart';
import 'package:mem/views/molecules/date_and_time_text_form_field.dart';

import '../../_helpers.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      ': date and time is null',
      (widgetTester) async {
        const dateAndTime = null;

        await runWidget(
          widgetTester,
          const DateAndTimeTextFormFieldV2(dateAndTime),
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
      },
      tags: TestSize.small,
    );
  });
}

final dateTextFormFieldFinder = find.byType(DateTextFormFieldV2);
