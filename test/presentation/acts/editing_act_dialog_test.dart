import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';

void main() {
  group('EditingActDialog test', () {
    test('should create EditingActDialog widget', () {
      const dialog = EditingActDialog(1);
      expect(dialog, isA<EditingActDialog>());
    });
  });
}
