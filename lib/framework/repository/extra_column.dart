import 'package:mem/framework/database/definition/column/column_definition.dart';

abstract class ExtraColumn {
  final ColumnDefinition column;

  ExtraColumn(this.column);

  String get toQuery;
}

class Max extends ExtraColumn {
  Max(super.column);

  @override
  String get toQuery => "MAX ( ${column.name} )";

  @override
  String toString() => toQuery;
}
