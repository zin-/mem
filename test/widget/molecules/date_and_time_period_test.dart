import 'package:flutter_test/flutter_test.dart';
import 'package:mem/views/molecules/date_and_time_period.dart';

import '../../_helpers.dart';

void main() {
  group('View', () {
    testWidgets(
      'description',
      (widgetTester) async {
        await runWidget(
          widgetTester,
          DateAndTimePeriodFields(),
        );
      },
    );
  });
}
