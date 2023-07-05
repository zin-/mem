import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';

void main() {
  group('Instantiation', () {
    test(': copyWith', () {
      final base = Act(1, DateAndTimePeriod.startNow());

      final copied = Act.copyWith(base);

      expect(copied.toString(), base.toString());
    });
  });
}
