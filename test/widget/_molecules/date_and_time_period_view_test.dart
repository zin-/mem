import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/views/_molecules/date_and_time_period_view.dart';

import '../../_helpers.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      'description',
      (widgetTester) async {
        final dateAndTimePeriod = DateAndTimePeriod(null, null);

        await runWidget(
          widgetTester,
          DateAndTimePeriodView(dateAndTimePeriod),
        );


      },
      tags: TestSize.small,
    );
  });
}
