import 'package:mem/framework/database/definition/column_type.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

class ColumnDefinition {
  final String name;
  final ColumnType type;
  final bool notNull;

  ColumnDefinition(
    this.name,
    this.type, {
    this.notNull = true,
  }) {
    if (name.isEmpty) {
      throw ColumnDefinitionException('Column name is empty.');
    } else if (name.contains(' ')) {
      throw ColumnDefinitionException('Column name contains " ".');
    }
  }

  String buildCreateTableSql() => '$name'
      ' ${type._buildCreateTableSql()}'
      '${notNull ? ' NOT NULL' : ''}';

  // ISSUE 209
  //  ここで定義されるべきものか？
  //  Databaseごとに変わる気もするし、ここではない気がする
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

extension on ColumnType {
  String _buildCreateTableSql() {
    switch (this) {
      case ColumnType.integer:
        return 'INTEGER';
      case ColumnType.text:
        return 'TEXT';
      case ColumnType.datetime:
        // FIXME TIMESTAMPは2038年問題があるのでDATETIMEに変更する
        return 'TIMESTAMP';
    }
  }
}
