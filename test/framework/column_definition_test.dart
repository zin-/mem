import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/column/column_type.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

void main() {
  group('Column', () {
    group(': new', () {
      test(
        ': success.',
        () {
          const columnName = 'test';

          final columnDefinition =
              ColumnDefinition(columnName, ColumnType.text);

          expect(columnDefinition.toString(), contains(columnName));
        },
      );

      test(
        ': empty name.',
        () {
          expect(
            () => ColumnDefinition('', ColumnType.text),
            throwsA(
              (e) =>
                  e is ColumnDefinitionException &&
                  e.toString() == 'Column name is empty.',
            ),
          );
        },
      );

      test(
        ': contains space.',
        () {
          expect(
            () => ColumnDefinition('test column', ColumnType.text),
            throwsA(
              (e) =>
                  e is ColumnDefinitionException &&
                  e.toString() == 'Column name contains " ".',
            ),
          );
        },
      );
    });
  });
}
