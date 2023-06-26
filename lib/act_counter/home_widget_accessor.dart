import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mem/logger/log_service.dart';

/// # Home widget
///
/// Flutterにおける正式名称が"Home widget"なのかもはっきりしていない
///
/// ## Package
///
/// - [home_widget](https://pub.dev/packages/home_widget)
///   - これを利用するので、暫定的に"Home widget"としている
/// - [workmanager](https://pub.dev/packages/workmanager)
///   - home_widgetで利用しているので、README通りに利用する
///
/// ## Reference
///
/// - https://developer.android.com/guide/topics/appwidgets?hl=ja
class HomeWidgetAccessor {
  Future<int> initialize(
    String methodChannelName,
    String initializeMethodName,
  ) =>
      v(
        () async => (await MethodChannel(methodChannelName)
            .invokeMethod<int>(initializeMethodName))!,
        {
          'methodChannelName': methodChannelName,
          'initializeMethodName': initializeMethodName,
        },
      );

  Future<bool> saveWidgetData(String key, dynamic value) => v(
        () async => (await HomeWidget.saveWidgetData(key, value))!,
        {'key': key, 'value': value},
      );

  Future<bool> updateWidget(String widgetName) => v(
        () async => (await HomeWidget.updateWidget(name: widgetName))!,
        {'widgetName': widgetName},
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
