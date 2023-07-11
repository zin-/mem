import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

void main() {
  test(
    'Column name contains "-".',
    () => expect(
      () => IntegerColumnDefinition('has-hyphen'),
      throwsA(
        (e) {
          expect(e, isA<ColumnDefinitionException>());
          expect(e.message, 'Column name contains "-".');
          return true;
        },
      ),
    ),
  );
}
