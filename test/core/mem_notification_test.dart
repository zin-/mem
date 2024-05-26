import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';

void main() {
  group('MemNotification', () {
    test('repeat by day of week.', () {
      const memId = 1;
      const time = 2;

      final repeatByDayOfWeek = MemNotification.repeatByDayOfWeek(memId, time);

      expect(repeatByDayOfWeek.isRepeatByDayOfWeek(), isTrue);
      expect(repeatByDayOfWeek.memId, equals(memId));
      expect(repeatByDayOfWeek.time, equals(time));
    });
  });

  test('MemNotificationType from unexpected name throw.', () {
    const name = 'unexpected name';

    expect(
      () => MemNotificationType.fromName(name),
      throwsA(
        (e) {
          expect(e.message, 'Unexpected name: "$name".');
          return true;
        },
      ),
    );
  });
}
