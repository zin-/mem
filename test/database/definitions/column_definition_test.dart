import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/definitions/column_definition.dart';

import '../../_helpers.dart';

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
        tags: TestSize.small,
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
        tags: TestSize.small,
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
        tags: TestSize.small,
      );
    });
  });
}
