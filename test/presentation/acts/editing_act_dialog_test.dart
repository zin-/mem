import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';

const _name = 'EditingActDialog test';

void main() {
  group(_name, () {
    test('should create EditingActDialog widget', () {
      const dialog = EditingActDialog(1);
      expect(dialog, isA<EditingActDialog>());
    });
  });
}
