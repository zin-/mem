import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final compositePkTable = TableDefinition(
  'test_table',
  [
    IntegerColumnDefinition('pk_1', isPrimaryKey: true),
    TextColumnDefinition('pk_2', isPrimaryKey: true),
  ],
  singularName: 'singular_name',
);

void main() {
  test(
    'Parent table has multiple primary keys.',
    () => expect(
      () => ForeignKeyDefinition(compositePkTable),
      throwsA((e) {
        expect(e, isA<UnimplementedError>());
        expect(
          e.message,
          'Parent table: "${compositePkTable.name}" has multiple primary keys.',
        );
        return true;
      }),
    ),
  );
}
