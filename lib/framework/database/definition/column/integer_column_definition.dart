import 'column_definition.dart';

class IntegerColumnDefinition extends ColumnDefinition {
  IntegerColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'INTEGER');
}
