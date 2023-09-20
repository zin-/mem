import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/column/column_type.dart';
import 'package:mem/framework/database/definition/column/primary_key_definition.dart';

final defPkId =
    PrimaryKeyDefinition('id', ColumnType.integer, autoincrement: true);
final defColCreatedAt = ColumnDefinition('createdAt', ColumnType.datetime);
final defColUpdatedAt =
    ColumnDefinition('updatedAt', ColumnType.datetime, notNull: false);
final defColArchivedAt =
    ColumnDefinition('archivedAt', ColumnType.datetime, notNull: false);

final defColsBase = [
  defPkId,
  defColCreatedAt,
  defColUpdatedAt,
  defColArchivedAt,
];
