import 'column_definition.dart';

class TimestampColumnDefinition extends ColumnDefinition {
  TimestampColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'TIMESTAMP');
}
