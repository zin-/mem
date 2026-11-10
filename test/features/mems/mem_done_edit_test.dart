import 'package:mem/features/mems/mem_done_edit.dart';
import 'package:test/test.dart';

void main() {
  group('MemDoneEdit', () {
    void onChanged(bool? value) {}

    test('is absent when undone children remain and the parent is undone', () {
      expect(
        MemDoneEdit.of(
          hasUndoneChildren: true,
          isDone: false,
          onChanged: onChanged,
        ),
        isNull,
      );
    });

    test(
        'keeps the callback when undone children remain and the parent is done',
        () {
      expect(
        MemDoneEdit.of(
          hasUndoneChildren: true,
          isDone: true,
          onChanged: onChanged,
        )?.onChanged,
        same(onChanged),
      );
    });

    test('keeps the callback when there are no undone children', () {
      expect(
        MemDoneEdit.of(
          hasUndoneChildren: false,
          isDone: false,
          onChanged: onChanged,
        )?.onChanged,
        same(onChanged),
      );
    });

    test(
        'keeps the callback when the parent is done and there are no undone children',
        () {
      expect(
        MemDoneEdit.of(
          hasUndoneChildren: false,
          isDone: true,
          onChanged: onChanged,
        )?.onChanged,
        same(onChanged),
      );
    });
  });
}
