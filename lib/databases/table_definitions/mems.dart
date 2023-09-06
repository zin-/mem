import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/column_type.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defMemName = ColumnDefinition('name', ColumnType.text);
final defMemDoneAt =
    ColumnDefinition('doneAt', ColumnType.datetime, notNull: false);
final defMemStartOn =
    ColumnDefinition('notifyOn', ColumnType.datetime, notNull: false);
final defMemStartAt =
    ColumnDefinition('notifyAt', ColumnType.datetime, notNull: false);
final defMemEndOn =
    ColumnDefinition('endOn', ColumnType.datetime, notNull: false);
final defMemEndAt =
    ColumnDefinition('endAt', ColumnType.datetime, notNull: false);

final memTableDefinition = TableDefinition(
  'mems',
  [
    defMemName,
    defMemDoneAt,
    defMemStartOn,
    defMemStartAt,
    defMemEndOn,
    defMemEndAt,
    ...defaultColumnDefinitions
  ],
);
