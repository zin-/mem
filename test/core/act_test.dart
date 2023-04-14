import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time_period.dart';

void main() {
  test(
    'Create instance',
    () {
      const memId = 1;
      final actPeriod = DateAndTimePeriod.startNow();
      final act = Act(memId, actPeriod);

      expect(act.memId, same(memId));
      expect(act.period, same(actPeriod));
    },
  );

  test(
    'toString',
    () {
      const memId = 2;
      final actPeriod = DateAndTimePeriod.startNow();
      final act = Act(memId, actPeriod);

      expect(
        act.toString(),
        equals('{memId: ${memId.toString()}'
            ', period: ${actPeriod.toString()}}'),
      );
    },
  );
}
