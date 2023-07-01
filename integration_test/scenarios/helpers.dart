import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/mem_items.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';

String dateText(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String timeText(DateTime dateTime) {
  return '${dateTime.hour > 11 ? dateTime.hour - 12 : dateTime.hour}'
      ':${dateTime.minute < 10 ? 0 : ''}${dateTime.minute}'
      ' ${dateTime.hour > 11 ? 'PM' : 'AM'}';
}

String dateTimeText(DateTime dateTime) {
  return '${dateText(dateTime)} ${timeText(dateTime)}';
}

Future<void> resetDatabase(Database database) async {
  await database.getTable(actTableDefinition.name).delete();
  await database.getTable(memItemTableDefinition.name).delete();
  await database.getTable(memTableDefinition.name).delete();
}
