import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/column_definition.dart';

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
                  e.toString() == 'Column name is required.',
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
