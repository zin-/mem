import 'column_definition.dart';

class IntegerColumnDefinition extends ColumnDefinitionV2 {
  IntegerColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'INTEGER');
}
