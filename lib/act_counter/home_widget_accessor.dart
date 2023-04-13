import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mem/logger/i/api.dart';

class HomeWidgetAccessor {
  Future<int> initialize(
          String methodChannelName, String initializeMethodName) =>
      v(
        {
          methodChannelName: methodChannelName,
          initializeMethodName: initializeMethodName,
        },
        () async => (await MethodChannel(methodChannelName)
            .invokeMethod<int>(initializeMethodName))!,
      );

  Future<bool> saveWidgetData(String key, dynamic value) => v(
        {key: key, value: value},
        () async => (await HomeWidget.saveWidgetData(key, value))!,
      );

  Future<bool> updateWidget(String widgetName) => v(
        {widgetName: widgetName},
        () async => (await HomeWidget.updateWidget(name: widgetName))!,
      );

  HomeWidgetAccessor._();

  static HomeWidgetAccessor? _instance;

  factory HomeWidgetAccessor({HomeWidgetAccessor? instance}) {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = instance ?? HomeWidgetAccessor._();
    }
    return tmp;
  }
}
