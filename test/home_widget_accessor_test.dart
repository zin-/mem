import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart';

void main() {
  initializeLogger(Level.verbose);

  final homeWidgetAccessor = HomeWidgetAccessor();

  testWidgets(
    'initialize',
    (widgetTester) async {
      const channel = MethodChannel('test_channel');
      const initializeMethodName = 'test_method';

      final homeWidgetId = math.Random().nextInt(4294967296);
      widgetTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (methodCall) {
          if (methodCall.method == initializeMethodName &&
              methodCall.arguments == null) {
            return Future.value(homeWidgetId);
          } else {
            throw AssertionError(methodCall.toString());
          }
        },
      );

      final result = await homeWidgetAccessor.initialize(
        channel.name,
        initializeMethodName,
      );

      expect(result, homeWidgetId);
    },
  );

  testWidgets(
    'saveWidgetData',
    (widgetTester) async {
      const key = 'test-key';
      const value = 'test-value';

      const channel = MethodChannel('home_widget');
      const methodName = 'saveWidgetData';
      final returns = math.Random().nextBool();
      widgetTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (methodCall) {
          if (methodCall.method == methodName &&
              methodCall.arguments.length == 2 &&
              methodCall.arguments['id'] == key &&
              methodCall.arguments['data'] == value) {
            return Future.value(returns);
          } else {
            throw AssertionError(methodCall.toString());
          }
        },
      );

      final result = await homeWidgetAccessor.saveWidgetData(
        key,
        value,
      );

      expect(result, returns);
    },
  );

  testWidgets(
    'updateWidget',
    (widgetTester) async {
      const widgetName = 'test-widgetName';

      const channel = MethodChannel('home_widget');
      const methodName = 'updateWidget';
      final returns = math.Random().nextBool();
      widgetTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (methodCall) {
          if (methodCall.method == methodName &&
              methodCall.arguments.length == 4 &&
              methodCall.arguments['name'] == widgetName &&
              methodCall.arguments['android'] == null &&
              methodCall.arguments['ios'] == null &&
              methodCall.arguments['qualifiedAndroidName'] == null) {
            return Future.value(returns);
          } else {
            throw AssertionError(methodCall.toString());
          }
        },
      );

      final result = await homeWidgetAccessor.updateWidget(
        widgetName,
      );

      expect(result, returns);
    },
  );
}
