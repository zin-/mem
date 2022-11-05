import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domain/date_and_time.dart';

import '../_helpers.dart';

void main() {
  group('Create instance', () {
    group(': now', () {
      test(
        ': allDay is false',
        () {
          final dateAndTime = DateAndTime.now();
          final dateTime = DateTime.fromMicrosecondsSinceEpoch(
              dateAndTime.microsecondsSinceEpoch);

          expect(dateAndTime, isA<DateAndTime>());
          expect(dateAndTime, isA<DateTime>());

          final string = dateAndTime.toString();
          expect(string, '${dateTime.toString()}, isAllDay: false');
        },
        tags: TestSize.small,
      );

      test(
        ': allDay is true',
        () {
          final dateAndTime = DateAndTime.now(allDay: true);
          final dateTime = DateTime.fromMicrosecondsSinceEpoch(
              dateAndTime.microsecondsSinceEpoch);

          expect(dateAndTime, isA<DateAndTime>());
          expect(dateAndTime, isA<DateTime>());

          final string = dateAndTime.toString();
          expect(string, '${dateTime.toString()}, isAllDay: true');
        },
        tags: TestSize.small,
      );
    });
  });
}
