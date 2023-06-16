import 'package:mem/framework/database/definition.dart';
import 'package:mem/database/definitions/table_definition.dart';

class ColumnDefinition {
  final String name;
  final ColumnType type;
  final bool notNull;
  final dynamic defaultValue;

  ColumnDefinition(
    this.name,
    this.type, {
    this.notNull = true,
    this.defaultValue,
  }) {
    if (name.isEmpty) {
      throw ColumnDefinitionException('Column name is required.');
    } else if (name.contains(' ')) {
      throw ColumnDefinitionException('Column name contains " ".');
    }
  }

  String onSQL() => '$name ${type._onSQL}'
      '${notNull ? ' NOT NULL' : ''}'
      // FIXME defaultValueがDateTimeなどの場合、動かない気がする
      '${defaultValue == null ? notNull ? '' : ' DEFAULT NULL' : ' DEFAULT $defaultValue'}';

  dynamic toTuple(dynamic value) {
    switch (type) {
      case ColumnType.integer:
      case ColumnType.text:
        return value;
      case ColumnType.datetime:
        return value == null
            ? null
            : (value as DateTime).toUtc().toIso8601String();
    }
  }

  dynamic fromTuple(dynamic value) {
    switch (type) {
      case ColumnType.integer:
      case ColumnType.text:
        return value;
      case ColumnType.datetime:
        return value == null ? null : DateTime.parse(value).toLocal();
    }
  }

  @override
  String toString() => 'Column definition :: { name: $name }';
}

class PrimaryKeyDefinition extends ColumnDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String onSQL() => '${super.onSQL()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';

  @override
  String toString() => 'Primary key definition :: { name: $name }';
}

class ForeignKeyDefinition extends ColumnDefinition {
  final TableDefinition parentTableDefinition;

  ForeignKeyDefinition(this.parentTableDefinition)
      : super(
          [
            parentTableDefinition.name,
            parentTableDefinition.primaryKey.name,
          ].join('_'),
          parentTableDefinition.primaryKey.type,
        );

  @override
  String onSQL() => [
        super.onSQL(),
        'FOREIGN KEY ($name)'
            ' REFERENCES ${parentTableDefinition.name}'
            '(${parentTableDefinition.primaryKey.name})'
      ].join(', ');

  @override
  String toString() => 'Foreign key definition :: { name: $name }';
}

enum ColumnType { integer, text, datetime }

extension on ColumnType {
  static final _onSQLs = {
    ColumnType.integer: 'INTEGER',
    ColumnType.text: 'TEXT',
    ColumnType.datetime: 'TIMESTAMP',
  };

  String get _onSQL => _onSQLs[this]!;
}

class ColumnDefinitionException extends DatabaseDefinitionException {
  ColumnDefinitionException(super.message);
}
