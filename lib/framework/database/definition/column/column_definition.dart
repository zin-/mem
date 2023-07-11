import 'package:mem/framework/database/definition/exceptions.dart';

abstract class ColumnDefinition {
  final String name;
  final String type;
  final bool notNull;

  ColumnDefinition(this.name, this.type, {this.notNull = true}) {
    if (name.isEmpty) {
      throw ColumnDefinitionException('Column name is empty.');
    } else if (name.contains(' ')) {
      throw ColumnDefinitionException('Column name contains " ".');
    }
  }

  String buildCreateTableSql() => [
        name,
        type,
        notNull ? ' NOT NULL' : '',
      ].join(' ');

  @override
  String toString() => 'ColumnDefinition'
      ' : {'
      'name: $name'
      ', type: $type'
      ', notNull: $notNull'
      ' }';
}

// TODO add PK
// TODO add FK
