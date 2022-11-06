import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act/domain/act.dart';
import 'package:mem/act/domain/date_and_time_period.dart';

void main() {
  group('Create instance', () {
    test(': success', () {
      final actPeriod = DateAndTimePeriod.startNow();
      final act = Act(actPeriod);

      expect(act.period, actPeriod);
    });
  });
}
