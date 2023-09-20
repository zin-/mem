import 'column_definition.dart';

class BooleanColumnDefinition extends ColumnDefinitionV2 {
  BooleanColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'INTEGER');
}
