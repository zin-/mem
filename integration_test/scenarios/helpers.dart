import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/mem_items.dart';
import 'package:mem/database/table_definitions/mem_repeated_notifications.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/main.dart';

Future<void> runApplication() => main(languageCode: 'en');

String dateText(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String timeText(DateTime dateTime) {
  final hourOfPeriod = dateTime.hour > 11 ? dateTime.hour - 12 : dateTime.hour;
  return '${hourOfPeriod == 0 ? 12 : hourOfPeriod}'
      ':${dateTime.minute < 10 ? 0 : ''}${dateTime.minute}'
      ' ${dateTime.hour > 11 ? 'PM' : 'AM'}';
}

String dateTimeText(DateTime dateTime) {
  return '${dateText(dateTime)} ${timeText(dateTime)}';
}

Future<void> resetDatabase(Database database) async {
  await database.getTable(actTableDefinition.name).delete();
  await database.getTable(memItemTableDefinition.name).delete();
  await database.getTable(memRepeatedNotificationTableDefinition.name).delete();
  await database.getTable(memTableDefinition.name).delete();
}

final newMemFabFinder = find.byIcon(Icons.add);

final memNameOnDetailPageFinder = find.byType(TextFormField).at(0);
final calendarIconFinder = find.byIcon(Icons.calendar_month);
final timeIconFinder = find.byIcon(Icons.access_time_outlined);
final switchFinder = find.byType(Switch);
final clearIconFinder = find.byIcon(Icons.clear);
final okFinder = find.text('OK');

Finder memRepeatedNotificationOnDetailPageFinder() {
  switch (find.byType(TextFormField).evaluate().length) {
    case 5:
      // period does not have time
      return find.byType(TextFormField).at(3);

    default:
      throw Exception('on test.');
  }
}

Finder memMemoOnDetailPageFinder() {
  switch (find.byType(TextFormField).evaluate().length) {
    case 5:
      // period does not have time
      return find.byType(TextFormField).at(4);

    default:
      throw Exception('on test.');
  }
}

final saveMemFabFinder = find.byIcon(Icons.save_alt);
