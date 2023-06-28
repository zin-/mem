import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/_repository_v2.dart';

import '../main.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';
const widgetProviderName = 'ActCounterProvider';

class ActCounterRepository extends RepositoryV2<ActCounter, ActCounter> {
  final HomeWidgetAccessor _homeWidgetAccessor;

  @override
  Future<ActCounter> receive(ActCounter payload) => v(
        () async {
          final homeWidgetId = await _homeWidgetAccessor.initialize(
            methodChannelName,
            initializeMethodName,
          );

          InitializedActCounter(homeWidgetId, payload)
              .widgetData()
              .forEach((key, value) async {
            await _homeWidgetAccessor.saveWidgetData(key, value);
          });

          await _homeWidgetAccessor.updateWidget(widgetProviderName);

          return payload;
        },
        {'payload': payload},
      );

  @override
  Future<ActCounter> replace(ActCounter payload) => v(
        () async {
          payload.widgetData().forEach((key, value) async {
            await _homeWidgetAccessor.saveWidgetData(key, value);
          });

          await _homeWidgetAccessor.updateWidget(widgetProviderName);

          return payload;
        },
        {'payload': payload},
      );

  ActCounterRepository._(this._homeWidgetAccessor);

  static ActCounterRepository? _instance;

  factory ActCounterRepository() {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = ActCounterRepository._(
        HomeWidgetAccessor(),
      );
    }
    return tmp;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void initializeActCounter() {
  if (!Platform.isWindows) {
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }
}
