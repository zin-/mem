import 'package:mem/framework/database/definition/column/column_definition.dart';

class TimestampColumnDefinition extends ColumnDefinition {
  TimestampColumnDefinition(
    String name, {
    super.notNull,
    super.isPrimaryKey,
  }) : super(name, 'TIMESTAMP');
}
