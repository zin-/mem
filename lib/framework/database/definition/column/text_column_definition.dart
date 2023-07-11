import 'package:mem/framework/database/definition/column/column_definition.dart';

class TextColumnDefinition extends ColumnDefinition {
  TextColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'TEXT');
}
