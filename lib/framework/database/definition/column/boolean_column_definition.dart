import 'column_definition.dart';

class BooleanColumnDefinition extends ColumnDefinition {
  BooleanColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'INTEGER');
}
