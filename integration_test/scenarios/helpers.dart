import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/database_repository.dart';

// Database(DB) operations
Future<DatabaseAccessor> openTestDatabase(
  DatabaseDefinition databaseDefinition,
) async {
  DatabaseFactory.onTest = true;
  return await DatabaseRepository().receive(databaseDefinition);
}

Future<void> clearAllTestDatabaseRows(
  DatabaseDefinition databaseDefinition,
) async {
  final databaseAccessor = await openTestDatabase(databaseDefinition);
  for (var tableDefinition in databaseDefinition.tableDefinitions.reversed) {
    await databaseAccessor.delete(tableDefinition);
  }
}

// Application operations
Future<void> runApplication() => main(languageCode: 'en');

Future closeMemListFilter(WidgetTester widgetTester) async =>
    await widgetTester.tapAt(const Offset(0, 0));

// Finders
final newMemFabFinder = find.byIcon(Icons.add);
final saveMemFabFinder = find.byIcon(Icons.save_alt);
final calendarIconFinder = find.byIcon(Icons.calendar_month);
final timeIconFinder = find.byIcon(Icons.access_time_outlined);
final clearIconFinder = find.byIcon(Icons.clear);
final memListFilterButtonFinder = find.byIcon(Icons.filter_list);
final okFinder = find.text('OK');

//  On MemList filter
final showNotArchiveSwitchFinder = find.byType(Switch).at(0);
final showArchiveSwitchFinder = find.byType(Switch).at(1);

//  On MemDetail
final memNameOnDetailPageFinder = find.byType(TextFormField).at(0);
final memNotificationOnDetailPageFinder = find.byType(TextFormField).at(3);
final afterActStartedNotificationTimeOnDetailPageFinder =
    find.byType(TextFormField).at(4);
final afterActStartedNotificationMessageOnDetailPageFinder =
    find.byType(TextFormField).at(5);
final memMemoOnDetailPageFinder = find.byType(TextFormField).at(6);

// Constants
const waitSideEffectDuration = Duration(milliseconds: 1500);
final zeroDate = DateTime(0);
const datePlaceHolder = "M/d/y";

// Value builder
int randomInt([int max = 42949671]) => Random().nextInt(max);

String dateText(DateTime dateTime) =>
    '${dateTime.month}/${dateTime.day}/${dateTime.year}';

String timeText(DateTime dateTime) {
  final hourOfPeriod = dateTime.hour > 11 ? dateTime.hour - 12 : dateTime.hour;
  return '${hourOfPeriod == 0 ? 12 : hourOfPeriod}'
      ':${dateTime.minute < 10 ? 0 : ''}${dateTime.minute}'
      ' ${dateTime.hour > 11 ? 'PM' : 'AM'}';
}

String dateTimeText(DateTime dateTime) =>
    '${dateText(dateTime)} ${timeText(dateTime)}';
