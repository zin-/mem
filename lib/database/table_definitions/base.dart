import 'package:mem/framework/database/column_definition.dart';

final idPKDef =
    PrimaryKeyDefinition('id', ColumnType.integer, autoincrement: true);
final createdAtColDef = ColumnDefinition('createdAt', ColumnType.datetime);
final updatedAtColDef =
    ColumnDefinition('updatedAt', ColumnType.datetime, notNull: false);
final archivedAtColDef =
    ColumnDefinition('archivedAt', ColumnType.datetime, notNull: false);

final defaultColumnDefinitions = [
  idPKDef,
  createdAtColDef,
  updatedAtColDef,
  archivedAtColDef,
];
