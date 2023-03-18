import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/repositories/_repository_v2.dart';

import '../main.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';

String memIdKey(int homeWidgetId) => 'memId-$homeWidgetId';

String actCountKey(MemId memId) => 'actCount-$memId';

String lastUpdatedAtKey(MemId memId) => 'lastUpdatedAtSeconds-$memId';

String memNameKey(MemId memId) => 'memName-$memId';

class ActCounterRepository extends RepositoryV2<ActCounter, ActCounter> {
  @override
  Future<ActCounter> receive(ActCounter payload) => v(
        {'payload': payload},
        () async {
          final homeWidgetId = await const MethodChannel(methodChannelName)
              .invokeMethod(initializeMethodName);

          if (homeWidgetId is int) {
            await HomeWidget.saveWidgetData(
              memIdKey(homeWidgetId),
              payload.memId,
            );
            return payload;
          } else {
            throw Exception();
          }
        },
      );

  @override
  Future<ActCounter> replace(ActCounter payload) => v(
        {'payload': payload},
        () async {
          await HomeWidget.saveWidgetData(
            actCountKey(payload.memId),
            payload.actCount,
          );
          final lastUpdatedAtSeconds =
              payload.lastUpdatedAt?.millisecondsSinceEpoch.toDouble();
          await HomeWidget.saveWidgetData(
            lastUpdatedAtKey(payload.memId),
            lastUpdatedAtSeconds,
          );
          await HomeWidget.saveWidgetData(
            memNameKey(payload.memId),
            payload.name,
          );

          HomeWidget.updateWidget(name: 'ActCounterProvider');

          return payload;
        },
      );

  ActCounterRepository._();

  static ActCounterRepository? _instance;

  factory ActCounterRepository() {
    var tmp = _instance;
    if (tmp == null) {
      _instance = tmp = ActCounterRepository._();
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
