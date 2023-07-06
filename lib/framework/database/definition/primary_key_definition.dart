import 'package:mem/framework/database/definition/column_definition.dart';

class PrimaryKeyDefinition extends ColumnDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    super.notNull,
    super.defaultValue,
    this.autoincrement = false,
  });

  @override
  String buildCreateTableSql() => '${super.buildCreateTableSql()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';

  @override
  String toString() => 'Primary key definition :: { name: $name }';
}
