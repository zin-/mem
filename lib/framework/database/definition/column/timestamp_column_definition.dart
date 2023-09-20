import 'column_definition.dart';

class TimestampColumnDefinition extends ColumnDefinitionV2 {
  TimestampColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'TIMESTAMP');
}
