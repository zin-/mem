import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';

void main() {
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
