import 'package:mem/database/tables/base.dart';
import 'package:mem/framework/database/column_definition.dart';
import 'package:mem/framework/database/table_definition.dart';

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