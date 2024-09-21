import 'package:mem/framework/database/definition/column/column_definition.dart';

abstract class OrderBy {
  final ColumnDefinition columnDefinition;

  OrderBy(this.columnDefinition);

  String toQuery();
}

class Ascending extends OrderBy {
  Ascending(super.columnDefinition);

  @override
  String toQuery() => "${columnDefinition.name} ASC";
}

class Descending extends OrderBy {
  Descending(super.columnDefinition);

  @override
  String toQuery() => "${columnDefinition.name} DESC";
}
