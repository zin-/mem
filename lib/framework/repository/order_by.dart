import 'package:mem/framework/database/definition/column/column_definition.dart';

abstract class OrderBy {
  final ColumnDefinition columnDefinition;

  OrderBy(this.columnDefinition);

  String toQuery();
}

// class Ascending extends OrderBy {
//   Ascending(super.columnDefinition);
//
//   @override
//   String toQuery() => "${columnDefinition.name} ASC";
// }

class Descending extends OrderBy {
  Descending(super.columnDefinition);

  @override
  String toQuery() => "${columnDefinition.name} DESC";
}

class DescendingCoalesce extends OrderBy {
  final ColumnDefinition secondary;

  DescendingCoalesce(super.columnDefinition, this.secondary);

  @override
  String toQuery() =>
      'COALESCE(${columnDefinition.name}, ${secondary.name}) DESC';
}
