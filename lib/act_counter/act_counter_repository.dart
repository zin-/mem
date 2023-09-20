import 'package:flutter/foundation.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/repository.dart';

import 'act_counter.dart';
import 'home_widget_accessor.dart';

// see android\app\src\main\kotlin\zin\playground\mem\ActCounterConfigure.kt
const methodChannelName = 'zin.playground.mem/act_counter';
const initializeMethodName = 'initialize';
const widgetProviderName = 'ActCounterProvider';

class ActCounterRepository extends RepositoryV2<ActCounter, ActCounter> {
  final HomeWidgetAccessor? _homeWidgetAccessor;

  @override
  Future<ActCounter> receive(ActCounter payload) => v(
        () async {
          final homeWidgetId = await _homeWidgetAccessor?.initialize(
            methodChannelName,
            initializeMethodName,
          );

          if (homeWidgetId != null) {
            InitializedActCounter(homeWidgetId, payload)
                .widgetData()
                .forEach((key, value) async {
              await _homeWidgetAccessor?.saveWidgetData(key, value);
            });

            await _homeWidgetAccessor?.updateWidget(widgetProviderName);
          }

          return payload;
        },
        {'payload': payload},
      );

  @override
  Future<ActCounter> replace(ActCounter payload) => v(
        () async {
          payload.widgetData().forEach((key, value) async {
            await _homeWidgetAccessor?.saveWidgetData(key, value);
          });

          await _homeWidgetAccessor?.updateWidget(widgetProviderName);

          return payload;
        },
        {'payload': payload},
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  ActCounterRepository._(this._homeWidgetAccessor);

  static ActCounterRepository? _instance;

  factory ActCounterRepository() => _instance ??= ActCounterRepository._(
        defaultTargetPlatform == TargetPlatform.android
            ? HomeWidgetAccessor()
            : null,
      );
}
