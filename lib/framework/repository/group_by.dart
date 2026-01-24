import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/repository/extra_column.dart';

class GroupBy {
  final List<ColumnDefinition> columns;
  final List<ExtraColumn>? _extraColumns;

  GroupBy(
    this.columns, {
    List<ExtraColumn>? extraColumns,
  }) : _extraColumns = extraColumns;

  List<ExtraColumn>? get extraColumns => _extraColumns;

  String get toQuery => columns.map((e) => e.name).join(", ");

  List<String>? get toExtraColumns =>
      _extraColumns?.map((e) => e.toQuery).toList(growable: false);

  @override
  String toString() =>
      "${_extraColumns == null ? "" : "$_extraColumns "}GROUP BY $columns";
}
