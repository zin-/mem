import 'package:mem/framework/database/column_definition.dart';

const idColumnName = 'id';
const createdAtColumnName = 'createdAt';
const updatedAtColumnName = 'updatedAt';
const archivedAtColumnName = 'archivedAt';

final defaultColumnDefinitions = [
  ColumnDefinition(createdAtColumnName, ColumnType.datetime),
  ColumnDefinition(updatedAtColumnName, ColumnType.datetime, notNull: false),
  ColumnDefinition(archivedAtColumnName, ColumnType.datetime, notNull: false),
];
