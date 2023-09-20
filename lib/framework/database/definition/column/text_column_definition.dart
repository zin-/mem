import 'column_definition.dart';

class TextColumnDefinition extends ColumnDefinitionV2 {
  TextColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'TEXT');
}
