import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/mem_status.dart';

void main() {
  group('MemStatus', () {
    test('is notified when notifications are enabled', () {
      expect(
        MemStatus.of(
          isDone: false,
          hasEnabledNotifications: true,
          hasUndoneChildren: true,
        ),
        MemStatus.notified,
      );
    });

    test('stays notified when the mem is already done', () {
      expect(
        MemStatus.of(
          isDone: true,
          hasEnabledNotifications: true,
          hasUndoneChildren: false,
        ),
        MemStatus.notified,
      );
    });

    test('is an undone parent while undone children remain', () {
      expect(
        MemStatus.of(
          isDone: false,
          hasEnabledNotifications: false,
          hasUndoneChildren: true,
        ),
        MemStatus.undoneParent,
      );
    });

    test('is doneable once that parent is done', () {
      expect(
        MemStatus.of(
          isDone: true,
          hasEnabledNotifications: false,
          hasUndoneChildren: true,
        ),
        MemStatus.doneable,
      );
    });

    test('is doneable when there are no notifications or undone children', () {
      expect(
        MemStatus.of(
          isDone: false,
          hasEnabledNotifications: false,
          hasUndoneChildren: false,
        ),
        MemStatus.doneable,
      );
    });
  });
}
