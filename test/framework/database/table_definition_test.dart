import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

void main() {
  test(
    'Table name is empty.',
    () => expect(
      () => TableDefinition('', []),
      throwsA(
        (e) {
          expect(e, isA<TableDefinitionException>());
          expect(e.message, 'Table name is empty.');
          return true;
        },
      ),
    ),
  );
  test(
    'Table name contains " ".',
    () => expect(
      () => TableDefinition('has space', []),
      throwsA(
        (e) {
          expect(e, isA<TableDefinitionException>());
          expect(e.message, 'Table name contains " ".');
          return true;
        },
      ),
    ),
  );
  test(
    'Table name contains "-".',
    () => expect(
      () => TableDefinition('has-hyphen', []),
      throwsA(
        (e) {
          expect(e, isA<TableDefinitionException>());
          expect(e.message, 'Table name contains "-".');
          return true;
        },
      ),
    ),
  );

  test(
    'ColumnDefinitions are empty.',
    () => expect(
      () => TableDefinition('test_table', []),
      throwsA(
        (e) {
          expect(e, isA<TableDefinitionException>());
          expect(e.message, 'ColumnDefinitions are empty.');
          return true;
        },
      ),
    ),
  );
  test(
    'Duplicate column name.',
    () => expect(
      () => TableDefinition('test_table', [
        IntegerColumnDefinition('same_name'),
        TextColumnDefinition('same_name'),
      ]),
      throwsA(
        (e) {
          expect(e, isA<TableDefinitionException>());
          expect(e.message, 'Duplicate column name.');
          return true;
        },
      ),
    ),
  );
}
