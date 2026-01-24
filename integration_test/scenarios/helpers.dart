import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/main.dart';
import 'package:mem/values/constants.dart';

Future<DriftDatabaseAccessor> openTestDatabase(
  DatabaseDefinition databaseDefinition, {
  bool onTest = true,
}) async {
  setOnTest(onTest);
  return await DatabaseRepository().receive(databaseDefinition);
}

Future<void> clearAllTestDatabaseRows(
  DatabaseDefinition databaseDefinition,
) async {
  final accessor = await openTestDatabase(databaseDefinition);
  for (var tableDefinition in databaseDefinition.tableDefinitions.reversed) {
    await accessor.delete(tableDefinition, null);
  }
}

// Application operations
Future<void> runApplication() async => await main(languageCode: 'en');

Future closeMemListFilter(WidgetTester widgetTester) async =>
    await widgetTester.tapAt(const Offset(0, 0));

// Localization(l10n) texts
final l10n = buildL10n();

// Finders
final newMemFabFinder = find.byIcon(Icons.add);
final saveMemFabFinder = find.byIcon(Icons.save_alt);
final calendarIconFinder = find.byIcon(Icons.calendar_month);
final timeIconFinder = find.byIcon(Icons.access_time_outlined);
final clearIconFinder = find.byIcon(Icons.clear);
final searchIconFinder = find.byIcon(Icons.search);
final closeIconFinder = find.byIcon(Icons.close);
final filterListIconFinder = find.byIcon(Icons.filter_list);
final menuButtonIconFinder = find.byIcon(Icons.more_vert);
final startIconFinder = find.byIcon(Icons.play_arrow);
final stopIconFinder = find.byIcon(Icons.stop);
final pauseIconFinder = find.byIcon(Icons.pause);
final okFinder = find.text('OK');
final cancelFinder = find.text('Cancel');
final drawerIconFinder = find.descendant(
    of: find.descendant(
        of: find.byType(AppBar), matching: find.byType(IconButton)),
    matching: find.byType(DrawerButtonIcon));

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
const waitShowSoftwareKeyboardDuration = Duration(milliseconds: 400);
const waitSideEffectDuration = Duration(milliseconds: 700);
const waitLongSideEffectDuration = Duration(milliseconds: 3000);
final zeroDate = DateTime(0);
const datePlaceHolder = "M/d/y";
const maxRetryCount = 5;

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

extension TextAt on WidgetTester {
  Text textAt(int index) => widget<Text>(find.byType(Text).at(index));
}

enum MethodChannelMock {
  mem,
  flutterLocalNotifications,
  sharePlus,
  filePicker,
  permissionHandler,
  workmanagerForeground,
  workmanagerBackground,
}

extension Method on MethodChannelMock {
  MethodChannel get channel {
    switch (this) {
      case MethodChannelMock.mem:
        return methodChannel;
      case MethodChannelMock.flutterLocalNotifications:
        return const MethodChannel('dexterous.com/flutter/local_notifications');
      case MethodChannelMock.sharePlus:
        return const MethodChannel("dev.fluttercommunity.plus/share");
      case MethodChannelMock.filePicker:
        return MethodChannel(
          'miguelruivo.flutter.plugins.filepicker',
          defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS
              ? const JSONMethodCodec()
              : const StandardMethodCodec(),
        );
      case MethodChannelMock.permissionHandler:
        return const MethodChannel('flutter.baseflow.com/permissions/methods');
      case MethodChannelMock.workmanagerForeground:
        return const MethodChannel(
            "be.tramckrijte.workmanager/foreground_channel_work_manager");
      case MethodChannelMock.workmanagerBackground:
        return const MethodChannel(
            "be.tramckrijte.workmanager/background_channel_work_manager");
    }
  }
}

extension HandleMockMethodCallHandler on WidgetTester {
  void setMockMethodCallHandler(
    MethodChannelMock methodChannelMock,
    List<Future<Object?>? Function(MethodCall message)?> expectedMethodCallList,
  ) =>
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        methodChannelMock.channel,
        (message) async {
          if (expectedMethodCallList.isEmpty) {
            fail("lack of expectedMethodCallList: ${{
              'channel': methodChannelMock,
              'method': message.method,
              'arguments': message.arguments,
            }}.");
          }
          return await expectedMethodCallList.removeAt(0)?.call(message);
        },
      );

  void clearAllMockMethodCallHandler() {
    for (var e in MethodChannelMock.values) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(e.channel, null);
    }
  }

  void ignoreMockMethodCallHandler(MethodChannelMock methodChannelMock) {
    setMockMethodCallHandler(
        methodChannelMock,
        List.generate(
            1000,
            (index) => (m) async {
                  switch (methodChannelMock) {
                    case MethodChannelMock.mem:
                      switch (m.method) {
                        case requestPermissions:
                          return true;

                        default:
                          throw UnimplementedError();
                      }
                    case MethodChannelMock.flutterLocalNotifications:
                      switch (m.method) {
                        case 'initialize':
                          return true;

                        case 'getNotificationAppLaunchDetails':
                          return null;

                        case 'show':
                          return null;
                      }
                    case MethodChannelMock.sharePlus:
                      // TODO: Handle this case.
                      throw UnimplementedError();
                    case MethodChannelMock.filePicker:
                      // TODO: Handle this case.
                      throw UnimplementedError();
                    case MethodChannelMock.permissionHandler:
                      switch (m.method) {
                        case 'checkPermissionStatus':
                          return 1;
                      }
                    case MethodChannelMock.workmanagerForeground:
                      return true;
                    case MethodChannelMock.workmanagerBackground:
                      // TODO: Handle this case.
                      throw UnimplementedError();
                  }

                  return false;
                }));
  }
}

void helperCallback() => v(() {});
