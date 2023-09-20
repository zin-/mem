import 'package:mem/framework/database/definition/exceptions.dart';

import 'column_type.dart';

abstract class ColumnDefinitionV2 {
  final String name;
  final String type;
  final bool notNull;
  final bool isPrimaryKey;

  ColumnDefinitionV2(
    this.name,
    this.type, {
    this.notNull = true,
    this.isPrimaryKey = false,
  }) {
    // ISSUE #209
    //  以下のチェックは、CREATE文だけではエラーにならなかった
    //  テーブル操作をした際にエラーになる可能性があるため、コメントアウトで残しておく
    // if (name.isEmpty) {
    //   throw ColumnDefinitionException('Column name is empty.');
    // } else if (name.contains(' ')) {
    //   throw ColumnDefinitionException('Column name contains " ".');
    // } else
    if (name.contains('-')) {
      throw ColumnDefinitionException('Column name contains "-".');
    }
  }

  String buildCreateTableSql() => [
        name,
        type,
        notNull ? 'NOT NULL' : null,
      ].where((element) => element != null).join(' ');

  @override
  String toString() => [
        runtimeType.toString(),
        {
          'name': name,
          'type': type,
          'notNull': notNull,
          'isPrimaryKey': isPrimaryKey,
        },
      ].join(': ');
}

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
      throw ColumnDefinitionException('Column name is empty.');
    } else if (name.contains(' ')) {
      throw ColumnDefinitionException('Column name contains " ".');
    }
  }

  String buildCreateTableSql() => '$name'
      ' ${type._buildCreateTableSql()}'
      '${notNull ? ' NOT NULL' : ''}'
      '${defaultValue == null ? '' : ' DEFAULT ${toTuple(defaultValue)}'}';

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

