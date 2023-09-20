import 'package:mem/framework/database/definition/column/column_definition.dart';

class PrimaryKeyDefinition extends ColumnDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    super.notNull,
    this.autoincrement = false,
  });

  @override
  String buildCreateTableSql() => '${super.buildCreateTableSql()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';

  @override
  String toString() => 'Primary key definition :: { name: $name }';
}
