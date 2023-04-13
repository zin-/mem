import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/act_counter/home_widget_accessor.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/_repository_v2.dart';

import '../main.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';
const widgetProviderName = 'ActCounterProvider';

String memIdKey(int homeWidgetId) => 'memId-$homeWidgetId';

String actCountKey(MemId memId) => 'actCount-$memId';

String lastUpdatedAtKey(MemId memId) => 'lastUpdatedAtSeconds-$memId';

String memNameKey(MemId memId) => 'memName-$memId';

class ActCounterRepository extends RepositoryV2<ActCounter, ActCounter> {
  final HomeWidgetAccessor _homeWidgetAccessor;

  @override
  Future<ActCounter> receive(ActCounter payload) => v(
        {'payload': payload},
        () async {
          final homeWidgetId = await _homeWidgetAccessor.initialize(
            methodChannelName,
            initializeMethodName,
          );

          await _homeWidgetAccessor.saveWidgetData(
            memIdKey(homeWidgetId),
            payload.memId,
          );
          await _homeWidgetAccessor.saveWidgetData(
            actCountKey(payload.memId),
            payload.actCount,
          );
          await _homeWidgetAccessor.saveWidgetData(
            lastUpdatedAtKey(payload.memId),
            payload.lastUpdatedAt?.millisecondsSinceEpoch.toDouble(),
          );
          await _homeWidgetAccessor.saveWidgetData(
            memNameKey(payload.memId),
            payload.name,
          );

          await _homeWidgetAccessor.updateWidget(widgetProviderName);

          return payload;
        },
      );

  @override
  Future<ActCounter> replace(ActCounter payload) => v(
        {'payload': payload},
        () async {
          await _homeWidgetAccessor.saveWidgetData(
            actCountKey(payload.memId),
            payload.actCount,
          );
          final lastUpdatedAtSeconds =
              payload.lastUpdatedAt?.millisecondsSinceEpoch.toDouble();
          await _homeWidgetAccessor.saveWidgetData(
            lastUpdatedAtKey(payload.memId),
            lastUpdatedAtSeconds,
          );
          await _homeWidgetAccessor.saveWidgetData(
            memNameKey(payload.memId),
            payload.name,
          );

          await _homeWidgetAccessor.updateWidget(widgetProviderName);

          return payload;
        },
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
