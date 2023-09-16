import 'package:mem/framework/database/definition/exceptions.dart';

abstract class ColumnDefinition {
  final String name;
  final String type;
  final bool notNull;
  final bool isPrimaryKey;

  ColumnDefinition(
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
